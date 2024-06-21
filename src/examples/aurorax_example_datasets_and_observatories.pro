;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

pro aurorax_example_datasets_and_observatories
  ; list datasets
  datasets = aurorax_list_datasets()
  print,''
  print,'Found ' + strcompress(fix(n_elements(datasets)),/remove_all) + ' datasets when searching with no filter'
  print,''

  ; list datasets with filter
  datasets = aurorax_list_datasets(name='TREX_RGB')
  print,'Found ' + strcompress(fix(n_elements(datasets)),/remove_all) + ' datasets when filtering for "THEMIS_ASI"'
  help,datasets[0]
  print,''
  print,''

  ; list observatories
  observatories = aurorax_list_observatories('themis_asi')
  print,'Found ' + strcompress(fix(n_elements(datasets)),/remove_all) + ' observatories part of the "themis_asi" instrument array'
  print,''

  ; list observatories with filter
  obs_gill = aurorax_list_observatories('trex_rgb', uid='gill')
  print,'Retrieved and displaying the TREx RGB GILL observatory'
  help,obs_gill[0]
  print,''
end