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

pro aurorax_example_atm_forward

  ; set up request
  ;
  ; we'll ask for the basic information, just the height-integrated rayleighs values
  time_stamp = '2024-01-01T06:00:00'
  geo_lat = 51.04
  geo_lon = -114.05
  output_flags = aurorax_atm_forward_get_output_flags(/ENABLE_ONLY_HEIGHT_INTEGRATED_RAYLEIGHS)
  output_flags['altitudes'] = 1
  output_flags['emission_5577'] = 1

  ; make the request
  data = aurorax_atm_forward(time_stamp,geo_lat,geo_lon,output_flags)
  stop

  ; print results
  help,data
  print,''

  ; print the information we asked for
  print,'Height-integrated Rayleighs:'
  print,'  427.8nm: ' + strcompress(string(data.data.height_integrated_rayleighs_4278))

end