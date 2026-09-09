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
; Compile a single .pro file by name.
;
; Most IDL-AuroraX source files hold several routines and are named after
; none of them (`aurorax_search_helpers.pro` defines
; `aurorax_create_criteria_block`, `__aurorax_datetime_parser` and others).
; `resolve_routine` compiles the whole file when /compile_full_file is set,
; but then raises because the routine it was asked for does not exist. The
; compile has already happened at that point, so the error is swallowed.
;
; This is the same thing `aurorax_startup.pro` achieves with `.run`, done in
; a way that can be driven from a loop.
;-
pro __aurorax_test_compile_file, name
  compile_opt idl2, hidden

  catch, err
  if (err ne 0) then begin
    catch, /cancel
    return
  endif
  resolve_routine, name, /compile_full_file, /either
  catch, /cancel
end

;+
; :Description:
;       Compile the IDL-AuroraX library into the current session so the test
;       suites can call it.
;
;       This deliberately does not use `@aurorax_startup`, for two reasons:
;       that batch file phones home to GitHub for a version check, and it
;       aborts awkwardly when the AACGM coefficient files are not where it
;       expects. Tests need to run offline and deterministically.
;
; :Params:
;       repo_root: in, required, String
;         path to the root of the idl-aurorax checkout
;
; :Keywords:
;       quiet: in, optional, Boolean
;         suppress the per-file "Compiled module" chatter
;-
pro aurorax_test_load_library, repo_root, quiet = quiet
  compile_opt idl2

  src_dir = filepath('src', root_dir = repo_root)
  aacgm_dir = filepath('aacgm', root_dir = filepath('libs', root_dir = repo_root))

  ; put the library, the bundled AACGM code, and the test code on the path
  !path = expand_path('+' + src_dir) + path_sep(/search_path) + $
    expand_path('+' + aacgm_dir) + path_sep(/search_path) + !path

  ; silence "% Compiled module: ..." while loading
  old_quiet = !quiet
  if (keyword_set(quiet)) then !quiet = 1

  ; ---------------------------------------------------------------
  ; compile in the order the library itself declares
  ;
  ; Order matters. When a file calls a function that has not been compiled
  ; yet, IDL cannot tell `foo(x, /kw)` apart from an array subscript and
  ; reports a spurious syntax error on the keyword. aurorax_startup.pro
  ; already curates a working order (AACGM first, then helpers, then
  ; everything that depends on them), so we reuse it rather than maintaining
  ; a second copy that could drift out of step.
  ; ---------------------------------------------------------------
  startup_file = filepath('aurorax_startup.pro', root_dir = src_dir)
  ordered = list()
  if (file_test(startup_file)) then begin
    n_lines = file_lines(startup_file)
    if (n_lines gt 0) then begin
      lines = strarr(n_lines)
      openr, lun, startup_file, /get_lun
      readf, lun, lines
      free_lun, lun
      for i = 0, n_lines - 1 do begin
        this_line = strtrim(lines[i], 2)
        if (strmid(this_line, 0, 5) eq '.run ') then ordered.add, strtrim(strmid(this_line, 5), 2)
      endfor
    endif
  endif
  for i = 0, n_elements(ordered) - 1 do begin
    __aurorax_test_compile_file, ordered[i]
  endfor

  ; ---------------------------------------------------------------
  ; then anything in src/ that startup did not mention
  ;
  ; This is the safety net: a newly added source file that nobody wired into
  ; aurorax_startup.pro still gets compiled, and so still gets tested.
  ; ---------------------------------------------------------------
  all_files = file_search(src_dir, '*.pro', count = n_found)
  already = ordered.toArray()

  leftovers = list()
  for i = 0, n_found - 1 do begin
    this_file = all_files[i]

    ; the examples are crib sheets, not library code -- the examples_compile
    ; suite handles those, and treats a failure there as a test failure
    ; rather than silently swallowing it
    if (strpos(this_file, path_sep() + 'examples' + path_sep()) ne -1) then continue

    ; aurorax_startup.pro is a batch file, not a routine file -- feeding it to
    ; resolve_routine just produces syntax errors on its `.run` lines
    if (file_basename(this_file) eq 'aurorax_startup.pro') then continue

    base = file_basename(this_file, '.pro')
    if (n_elements(already) gt 0) then begin
      if ((where(already eq base))[0] ne -1) then continue
    endif
    leftovers.add, base
  endfor

  ; two passes over the leftovers, so that a pair of them referring to each
  ; other still resolves regardless of the order file_search returned
  for pass = 0, 1 do begin
    for i = 0, n_elements(leftovers) - 1 do begin
      __aurorax_test_compile_file, leftovers[i]
    endfor
  endfor

  ; restore
  !quiet = old_quiet
end
