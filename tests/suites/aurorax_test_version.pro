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
; The version number is written in four places: aurorax_version.pro,
; idlpackage.json, the README badge, and the top of RELEASE_NOTES.md. The
; release checklist in DEVELOPERS.md says to update them together, and they
; have drifted apart before -- aurorax_version.pro was left on 1.9.0 while
; the other files had moved on to 1.9.2, which meant the User-Agent header
; and the update check both reported a version that was two releases stale.
;
; These tests fail if they ever disagree again.

;+
; Read a whole text file into a single string.
;-
function __atest_read_text_file, path
  compile_opt idl2

  n = file_lines(path)
  if (n eq 0) then return, ''
  lines = strarr(n)
  openr, lun, path, /get_lun
  readf, lun, lines
  free_lun, lun
  return, strjoin(lines, string(10b))
end

pro aurorax_test_version
  compile_opt idl2

  ; tests/suites/<this file> -> repo root
  repo_root = file_dirname(file_dirname(file_dirname(routine_filepath('aurorax_test_version'))))

  version = __aurorax_version()

  ; -----------------------------------------------------------
  atest_suite, 'version -- shape'
  ; -----------------------------------------------------------
  atest_not_null, version, '__aurorax_version returns something'
  atest_true, isa(version, /string), 'the version is a string'

  parts = strsplit(version, '.', /extract)
  atest_n_elements, parts, 3, 'the version has three dot separated components'
  for i = 0, n_elements(parts) - 1 do begin
    digits_only = stregex(parts[i], '^[0-9]+$', /boolean)
    atest_true, digits_only, 'version component ' + strtrim(i, 2) + ' (''' + parts[i] + ''') is numeric'
  endfor

  ; -----------------------------------------------------------
  atest_suite, 'version -- agrees with idlpackage.json'
  ; -----------------------------------------------------------
  pkg_path = filepath('idlpackage.json', root_dir = repo_root)
  atest_true, file_test(pkg_path), 'idlpackage.json exists'
  if (file_test(pkg_path)) then begin
    pkg = json_parse(__atest_read_text_file(pkg_path))
    atest_has_key, pkg, 'Version', 'idlpackage.json declares a Version'
    if (pkg.hasKey('Version')) then begin
      atest_equal, pkg['Version'], version, $
        'idlpackage.json Version matches __aurorax_version()'
    endif
  endif

  ; -----------------------------------------------------------
  atest_suite, 'version -- agrees with the README badge'
  ; -----------------------------------------------------------
  readme_path = filepath('README.md', root_dir = repo_root)
  atest_true, file_test(readme_path), 'README.md exists'
  if (file_test(readme_path)) then begin
    readme = __atest_read_text_file(readme_path)
    atest_contains, readme, 'release-v' + version + '-', $
      'the README stable release badge shows the current version'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'version -- agrees with RELEASE_NOTES.md'
  ; -----------------------------------------------------------
  notes_path = filepath('RELEASE_NOTES.md', root_dir = repo_root)
  atest_true, file_test(notes_path), 'RELEASE_NOTES.md exists'
  if (file_test(notes_path)) then begin
    n_lines = file_lines(notes_path)
    if (n_lines gt 0) then begin
      lines = strarr(n_lines)
      openr, lun, notes_path, /get_lun
      readf, lun, lines
      free_lun, lun

      first_line = strtrim(lines[0], 2)
      atest_contains, first_line, 'Version ' + version, $
        'the newest RELEASE_NOTES.md entry is for the current version'
    endif
  endif
end
