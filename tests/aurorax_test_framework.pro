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
; A small, dependency-free assertion framework for the IDL-AuroraX test
; suite. It exists so that the tests can be run with nothing more than a
; stock IDL install -- no mgunit, no external packages.
;
; State lives in a common block rather than on the heap so that an
; aborted run cannot leak objects.

; -------------------------------------------------------------
; state management
; -------------------------------------------------------------

pro atest_init
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  n_total = 0l
  n_passed = 0l
  n_failed = 0l
  failure_list = list()
  suite_name = '(none)'
  verbose_flag = 1

  ; 0 means "no log file". Unit 0 is stdin, so it is never a valid write
  ; target and makes an unambiguous sentinel (-1 would mean stdout).
  log_lun = 0
end

pro atest_set_verbose, flag
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  verbose_flag = keyword_set(flag) ? 1 : 0
end

;+
; Mirror all framework output into a file as well as to stdout.
;
; This exists because IDL on Windows does not reliably flush stdout to a
; pipe before the process exits -- a scripted run can lose the tail of its
; own results, up to and including the pass/fail summary. Writing to a file
; we open, flush and close ourselves is deterministic.
;-
pro atest_open_log, filename
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  catch, err
  if (err ne 0) then begin
    catch, /cancel
    print, '  [WARN] could not open log file ''' + filename + ''': ' + !error_state.msg
    log_lun = 0
    return
  endif
  openw, unit, filename, /get_lun
  catch, /cancel
  log_lun = unit
end

pro atest_close_log
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  if (log_lun gt 0) then begin
    flush, log_lun
    free_lun, log_lun
    log_lun = 0
  endif
end

;+
; Emit one line of framework output, to stdout and to the log file if one
; is open. Every print in this file goes through here.
;-
pro atest_print, msg
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  print, msg
  if (log_lun gt 0) then printf, log_lun, msg
end

pro atest_suite, name
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  suite_name = name
  if (verbose_flag eq 1) then begin
    atest_print, ''
    atest_print, '  ' + name
  endif
end

;+
; Print a note into the test output. Used to flag places where a function
; under test is expected to print its own error message, so that the
; surrounding noise in the log is understood to be intentional.
;-
pro atest_note, msg
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  if (verbose_flag eq 1) then atest_print, '    ... ' + msg
end

; -------------------------------------------------------------
; value rendering and comparison
; -------------------------------------------------------------

;+
; Render an arbitrary IDL value as a short string for failure messages.
;-
function atest_repr, value
  compile_opt idl2

  ; undefined / !null
  if (n_elements(value) eq 0) then return, '!null'

  ; objects and structs get described by shape rather than contents
  if (isa(value, 'HASH')) then return, 'HASH(' + strtrim(n_elements(value), 2) + ' keys)'
  if (isa(value, 'LIST')) then return, 'LIST(' + strtrim(n_elements(value), 2) + ' elements)'
  if (size(value, /type) eq 8) then return, 'STRUCT(' + strtrim(n_tags(value), 2) + ' tags)'
  if (size(value, /type) eq 11) then return, 'OBJREF(' + typename(value) + ')'

  ; scalars and arrays
  if (n_elements(value) eq 1) then begin
    if (isa(value, /string)) then return, '''' + value + ''''
    return, strtrim(string(value), 2)
  endif

  ; array -- render up to the first 10 elements
  n_show = n_elements(value) < 10
  parts = strarr(n_show)
  for i = 0, n_show - 1 do parts[i] = strtrim(string(value[i]), 2)
  out = '[' + strjoin(parts, ', ')
  if (n_elements(value) gt n_show) then out = out + ', ...'
  return, out + ']'
end

;+
; Generic equality test that copes with !null, scalars, strings and arrays.
;-
function atest_values_equal, actual, expected
  compile_opt idl2

  ; both undefined
  actual_undefined = (n_elements(actual) eq 0)
  expected_undefined = (n_elements(expected) eq 0)
  if (actual_undefined and expected_undefined) then return, 1
  if (actual_undefined or expected_undefined) then return, 0

  ; differing element counts can never be equal
  if (n_elements(actual) ne n_elements(expected)) then return, 0

  ; scalar comparison
  if (n_elements(actual) eq 1) then begin
    ; float comparison falls through to the caller's tolerance-aware helper,
    ; here we do an exact comparison
    return, (actual eq expected) ? 1 : 0
  endif

  ; array comparison
  return, array_equal(actual, expected) ? 1 : 0
end

; -------------------------------------------------------------
; core assertion
; -------------------------------------------------------------

;+
; The primitive every other assertion routes through.
;-
pro atest_ok, condition, description, detail = detail
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  n_total = n_total + 1

  if (keyword_set(condition)) then begin
    n_passed = n_passed + 1
    if (verbose_flag eq 1) then atest_print, '    [PASS] ' + description
  endif else begin
    n_failed = n_failed + 1
    failure_list.add, {suite: suite_name, description: description, detail: (n_elements(detail) eq 0) ? '' : detail}
    atest_print, '    [FAIL] ' + description
    if (n_elements(detail) ne 0) then begin
      if (detail ne '') then atest_print, '           ' + detail
    endif
  endelse
end

; -------------------------------------------------------------
; assertions
; -------------------------------------------------------------

pro atest_equal, actual, expected, description
  compile_opt idl2

  is_equal = atest_values_equal(actual, expected)
  detail = 'expected ' + atest_repr(expected) + ' but got ' + atest_repr(actual)
  atest_ok, is_equal, description, detail = detail
end

pro atest_not_equal, actual, expected, description
  compile_opt idl2

  is_equal = atest_values_equal(actual, expected)
  detail = 'expected a value different from ' + atest_repr(expected)
  atest_ok, ~is_equal, description, detail = detail
end

pro atest_true, value, description
  compile_opt idl2

  atest_ok, keyword_set(value), description, detail = 'expected a true value, got ' + atest_repr(value)
end

pro atest_false, value, description
  compile_opt idl2

  atest_ok, ~keyword_set(value), description, detail = 'expected a false value, got ' + atest_repr(value)
end

;+
; Assert a value is !null / undefined. Several AuroraX functions signal
; bad input by printing a message and returning !null, so this gets a lot
; of use in the error-path tests.
;-
pro atest_null, value, description
  compile_opt idl2

  atest_ok, (n_elements(value) eq 0), description, detail = 'expected !null, got ' + atest_repr(value)
end

pro atest_not_null, value, description
  compile_opt idl2

  atest_ok, (n_elements(value) ne 0), description, detail = 'expected a non-null value, got !null'
end

;+
; Float comparison with an absolute tolerance.
;-
pro atest_close, actual, expected, tolerance, description
  compile_opt idl2

  if (n_elements(actual) eq 0) then begin
    atest_ok, 0, description, detail = 'expected ' + atest_repr(expected) + ' but got !null'
    return
  endif

  diff = abs(double(actual) - double(expected))
  ok = max(diff) le tolerance
  detail = 'expected ' + atest_repr(expected) + ' (+/- ' + strtrim(string(tolerance), 2) + $
    ') but got ' + atest_repr(actual)
  atest_ok, ok, description, detail = detail
end

pro atest_contains, haystack, needle, description
  compile_opt idl2

  if (n_elements(haystack) eq 0) then begin
    atest_ok, 0, description, detail = 'expected a string containing ''' + needle + ''' but got !null'
    return
  endif

  found = strpos(haystack, needle) ne -1
  atest_ok, found, description, detail = 'expected to find ''' + needle + ''' in: ' + haystack
end

pro atest_not_contains, haystack, needle, description
  compile_opt idl2

  if (n_elements(haystack) eq 0) then begin
    atest_ok, 0, description, detail = 'expected a string but got !null'
    return
  endif

  found = strpos(haystack, needle) ne -1
  atest_ok, ~found, description, detail = 'did not expect to find ''' + needle + ''' in: ' + haystack
end

;+
; Assert a hash contains a given key.
;-
pro atest_has_key, h, key, description
  compile_opt idl2

  if (n_elements(h) eq 0) then begin
    atest_ok, 0, description, detail = 'expected a hash but got !null'
    return
  endif

  atest_ok, h.hasKey(key), description, detail = 'expected hash to contain key ''' + key + ''''
end

;+
; Assert that a struct has a given tag (case-insensitive, as IDL tags are).
;-
pro atest_has_tag, s, tag, description
  compile_opt idl2

  if (n_elements(s) eq 0) then begin
    atest_ok, 0, description, detail = 'expected a struct but got !null'
    return
  endif

  names = tag_names(s)
  found = (where(names eq strupcase(tag)))[0] ne -1
  atest_ok, found, description, detail = 'expected struct to have tag ''' + tag + ''', has: ' + strjoin(names, ', ')
end

pro atest_n_elements, value, expected_count, description
  compile_opt idl2

  actual_count = n_elements(value)
  detail = 'expected ' + strtrim(expected_count, 2) + ' elements, got ' + strtrim(actual_count, 2)
  atest_ok, actual_count eq expected_count, description, detail = detail
end

;+
; Assert that evaluating an IDL statement raises an error.
;
; The statement is given as a string and run through EXECUTE, which returns
; 0 when the statement failed. Variables in the calling suite are visible to
; it, so `atest_raises, 'x = foo(bar)', '...'` works with a local `bar`.
;
; Used to pin down the handful of routines that fault on bad input rather
; than returning !null the way most of the library does.
;-
pro atest_raises, statement, description
  compile_opt idl2

  ; EXECUTE prints the underlying error itself; the caller is expected to
  ; have flagged that with atest_note.
  ok = execute(statement, 1, 1)
  atest_ok, ok eq 0, description, $
    detail = 'expected ''' + statement + ''' to raise, but it succeeded'
end

;+
; The inverse: assert that a statement runs without raising.
;-
pro atest_no_raise, statement, description
  compile_opt idl2

  ok = execute(statement, 1, 1)
  atest_ok, ok eq 1, description, $
    detail = 'expected ''' + statement + ''' to run cleanly, but it raised'
end

;+
; Assert that the supplied JSON string parses, and return the parsed hash
; through the `parsed` keyword so the caller can make further assertions.
;-
pro atest_valid_json, json_str, description, parsed = parsed
  compile_opt idl2

  parsed = !null
  if (n_elements(json_str) eq 0) then begin
    atest_ok, 0, description, detail = 'expected a JSON string but got !null'
    return
  endif

  catch, err
  if (err ne 0) then begin
    catch, /cancel
    atest_ok, 0, description, detail = 'json_parse failed: ' + !error_state.msg
    return
  endif
  parsed = json_parse(json_str)
  catch, /cancel

  atest_ok, 1, description
end

; -------------------------------------------------------------
; reporting
; -------------------------------------------------------------

;+
; Print the run summary. Returns 0 if everything passed, 1 otherwise, so
; that the runner can turn it into a process exit code.
;-
function atest_summary
  compile_opt idl2
  common aurorax_test_state, n_total, n_passed, n_failed, failure_list, suite_name, verbose_flag, log_lun

  atest_print, ''
  atest_print, '================================================================'
  if (n_failed eq 0) then begin
    atest_print, ' PASSED -- ' + strtrim(n_passed, 2) + ' of ' + strtrim(n_total, 2) + ' assertions'
    atest_print, '================================================================'
    return, 0
  endif

  atest_print, ' FAILED -- ' + strtrim(n_failed, 2) + ' of ' + strtrim(n_total, 2) + ' assertions failed'
  atest_print, '================================================================'
  atest_print, ''
  for i = 0, n_elements(failure_list) - 1 do begin
    f = failure_list[i]
    atest_print, '  ' + f.suite + ': ' + f.description
    if (f.detail ne '') then atest_print, '      ' + f.detail
  endfor
  atest_print, ''
  return, 1
end
