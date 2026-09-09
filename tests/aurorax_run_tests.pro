; -------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; -------------------------------------------------------------

;+
; :Description:
;       Run the IDL-AuroraX test suite.
;
;       Suites are discovered automatically: every `.pro` file in
;       `tests/suites/` is expected to define a procedure whose name matches
;       the file's basename. To add a new suite, drop a file in that
;       directory -- no changes are needed here.
;
;       By default only the offline suites run. Suites whose basename ends
;       in `_online` reach out to the AuroraX API and are skipped unless
;       /online is set.
;
; :Keywords:
;       filter: in, optional, String
;         only run suites whose name contains this substring
;       online: in, optional, Boolean
;         also run the suites that require network access
;       quiet: in, optional, Boolean
;         only report failures and the final summary
;       exit_on_finish: in, optional, Boolean
;         call `exit` with a status code when done (0 = pass, 1 = fail).
;         Used by the CI wrappers; leave unset when running interactively
;         so that a failing test does not close your IDL session.
;       loud_compile: in, optional, Boolean
;         show the "Compiled module" chatter while loading the library.
;         Useful when diagnosing a compile problem in the library itself.
;       logfile: in, optional, String
;         also write the results to this file. Recommended for scripted
;         runs -- see the note about stdout flushing at the end of this
;         routine.
;
; :Examples:
;       aurorax_run_tests
;       aurorax_run_tests, filter='datetime'
;       aurorax_run_tests, /online
;-
pro aurorax_run_tests, filter = filter, online = online, quiet = quiet, $
  exit_on_finish = exit_on_finish, loud_compile = loud_compile, logfile = logfile
  compile_opt idl2

  ; work out where we live, and from that where the repo root is
  tests_dir = file_dirname(routine_filepath('aurorax_run_tests'))
  repo_root = file_dirname(tests_dir)
  suites_dir = filepath('suites', root_dir = tests_dir)

  ; put the test code on the search path so suites resolve by name
  ;
  ; NOTE: '+' means recurse. We prepend rather than append so that the
  ; checkout under test always wins over any other idl-aurorax install
  ; the user may have on their path (e.g. one installed via ipm).
  !path = expand_path('+' + tests_dir) + path_sep(/search_path) + !path

  ; compile the library under test
  aurorax_test_load_library, repo_root, quiet = ~keyword_set(loud_compile)

  ; compile the assertion framework
  ;
  ; It holds many routines and is named after none of them, so it will not
  ; auto-resolve on first use the way a single-routine file would.
  __aurorax_test_compile_file, 'aurorax_test_framework'

  ; reset framework state, and start mirroring output to the log if asked
  atest_init
  if (n_elements(logfile) ne 0) then atest_open_log, logfile
  if (keyword_set(quiet)) then atest_set_verbose, 0

  ; header
  atest_print, '================================================================'
  atest_print, ' IDL-AuroraX test suite'
  atest_print, '================================================================'
  atest_print, ' IDL version:  ' + !version.release + ' (' + !version.os + ', ' + !version.arch + ')'
  atest_print, ' Repo root:    ' + repo_root
  if (keyword_set(online)) then begin
    atest_print, ' Mode:         offline + online (network tests enabled)'
  endif else begin
    atest_print, ' Mode:         offline only (use /online to include network tests)'
  endelse

  ; discover suites
  suite_files = file_search(suites_dir, '*.pro', count = n_suites)
  if (n_suites eq 0) then begin
    atest_print, ''
    atest_print, ' ERROR: no test suites found in ' + suites_dir
    atest_close_log
    if (keyword_set(exit_on_finish)) then begin
      wait, 2
      exit, status = 1
    endif
    return
  endif

  ; work out the procedure name for each suite, and decide what to run
  suite_names = strarr(n_suites)
  for i = 0, n_suites - 1 do begin
    suite_names[i] = file_basename(suite_files[i], '.pro')
  endfor
  suite_names = suite_names[sort(suite_names)]

  n_run = 0l
  n_skipped = 0l
  skipped_names = list()
  errored_names = list()

  for i = 0, n_suites - 1 do begin
    this_suite = suite_names[i]

    ; apply the name filter, if one was given
    if (n_elements(filter) ne 0) then begin
      if (strpos(this_suite, filter) eq -1) then continue
    endif

    ; skip network suites unless explicitly asked for
    is_online_suite = strmid(this_suite, strlen(this_suite) - 7) eq '_online'
    if (is_online_suite and ~keyword_set(online)) then begin
      n_skipped = n_skipped + 1
      skipped_names.add, this_suite
      continue
    endif

    ; run it, but do not let one broken suite take down the whole run
    catch, err
    if (err ne 0) then begin
      catch, /cancel
      atest_print, ''
      atest_print, '    [ERROR] suite ' + this_suite + ' raised: ' + !error_state.msg
      errored_names.add, this_suite
      atest_ok, 0, 'suite ' + this_suite + ' ran to completion', $
        detail = 'unhandled error: ' + !error_state.msg
      continue
    endif
    call_procedure, this_suite
    catch, /cancel

    n_run = n_run + 1
  endfor

  ; summary
  status = atest_summary()

  atest_print, ' Suites run:     ' + strtrim(n_run, 2)
  if (n_skipped gt 0) then begin
    atest_print, ' Suites skipped: ' + strtrim(n_skipped, 2) + ' (network) -- ' + strjoin(skipped_names.toArray(), ', ')
  endif
  if (n_elements(errored_names) gt 0) then begin
    atest_print, ' Suites errored: ' + strjoin(errored_names.toArray(), ', ')
  endif
  atest_print, ''
  atest_close_log

  ; exit with a status code when asked (CI)
  ;
  ; The wait is not cosmetic. On Windows, IDL does not reliably drain stdout
  ; into a pipe before `exit` tears the process down, so a scripted run can
  ; lose the tail of its own output -- summary included. Giving it a moment
  ; first avoids that. The log file written above is the reliable copy.
  if (keyword_set(exit_on_finish)) then begin
    flush, -1
    wait, 2
    exit, status = status
  endif
end
