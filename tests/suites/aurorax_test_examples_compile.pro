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
;
; The crib sheets under src/examples are the library's documentation, and
; they are the first thing a new user runs. They are not exercised by
; anything else in this suite -- actually running them would download data
; and open plot windows -- but they can at least be compiled, which catches
; renamed keywords, dropped arguments and typos.
;
; Each crib sheet is named after the procedure it defines, so a successful
; compile is checked by asking whether that procedure now resolves.

pro aurorax_test_examples_compile
  compile_opt idl2

  ; tests/suites/<this file> -> repo root
  repo_root = file_dirname(file_dirname(file_dirname(routine_filepath('aurorax_test_examples_compile'))))
  examples_dir = filepath('examples', root_dir = filepath('src', root_dir = repo_root))

  atest_suite, 'crib sheets compile'

  if (~file_test(examples_dir, /directory)) then begin
    atest_ok, 0, 'the examples directory exists', detail = 'looked in ' + examples_dir
    return
  endif

  files = file_search(examples_dir, '*.pro', count = n_files)
  atest_true, n_files gt 0, 'found crib sheets to compile'
  if (n_files eq 0) then return

  ; compile them all first, quietly -- a broken one prints its own syntax
  ; error, which is the detail a developer needs
  old_quiet = !quiet
  !quiet = 1
  for i = 0, n_files - 1 do begin
    __aurorax_test_compile_file, file_basename(files[i], '.pro')
  endfor
  !quiet = old_quiet

  ; now check each one actually produced its procedure
  compiled = routine_info()
  n_ok = 0l
  failed = list()
  for i = 0, n_files - 1 do begin
    expected = strupcase(file_basename(files[i], '.pro'))
    if ((where(compiled eq expected))[0] ne -1) then begin
      n_ok = n_ok + 1
    endif else begin
      failed.add, file_basename(files[i])
    endelse
  endfor

  atest_equal, n_ok, n_files, $
    'all ' + strtrim(n_files, 2) + ' crib sheets compiled'

  ; name the ones that failed, so the log points straight at them rather
  ; than just reporting a count
  if (n_elements(failed) gt 0) then begin
    for i = 0, n_elements(failed) - 1 do begin
      atest_ok, 0, 'crib sheet ' + failed[i] + ' compiled', $
        detail = 'the procedure it should define did not resolve -- look for a syntax error above'
    endfor
  endif
end
