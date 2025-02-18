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

pro aurorax_example_data_products_search
  compile_opt idl2

  ; perform search
  response = aurorax_data_product_search('2020-01-01T00:00', '2020-01-01T23:59', programs = ['trex'], platforms = ['fort smith'], instrument_types = ['RGB ASI'])

  ; show output
  help, response
  print, ''

  help, response.data[0]
  print, ''
end
