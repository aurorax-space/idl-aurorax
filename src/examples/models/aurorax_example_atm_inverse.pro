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

pro aurorax_example_atm_inverse
  ; set up request
  ;
  ; we'll ask for the basic information: energy flux, characteristic energy,
  ; and oxygen correction factor
  time_stamp = '2021-10-12T06:00:00'
  geo_lat = 58.227808
  geo_lon = -103.680631

  intensity_4278 = 2302.6
  intensity_5577 = 11339.5
  intensity_6300 = 528.3
  intensity_8446 = 427.4

  output_flags = aurorax_atm_inverse_get_output_flags()
  output_flags['energy_flux'] = 1
  output_flags['characteristic_energy'] = 1
  output_flags['oxygen_correction_factor'] = 1

  ; make the request
  data = aurorax_atm_inverse(time_stamp, geo_lat, geo_lon, intensity_4278, intensity_5577, intensity_6300, intensity_8446, output_flags)

  ; print results
  help, data
  print, ''

  ; print the information we asked for
  print, 'Energy Flux:              ' + strcompress(string(data.data.energy_flux)) + ' erg/cm2/s'
  print, 'Characteristic Energy:    ' + strcompress(string(data.data.characteristic_energy)) + ' eV'
  print, 'Oxygen Correction Factor: ' + strcompress(string(data.data.oxygen_correction_factor))
end
