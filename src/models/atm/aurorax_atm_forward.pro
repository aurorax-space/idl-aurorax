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

function aurorax_atm_forward,$
  time_stamp,$
  geo_lat,$
  geo_lon,$
  output_flags,$
  maxwellian_energy_flux=maxwellian_energy_flux,$
  gaussian_energy_flux=gaussian_energy_flux,$
  maxwellian_characteristic_energy=maxwellian_characteristic_energy,$
  gaussian_peak_energy=gaussian_peak_energy,$
  gaussian_spectral_width=gaussian_spectral_width,$
  nrlmsis_model_version=nrlmsis_model_version,$
  oxygen_correction_factor=oxygen_correction_factor,$
  timescale_auroral=timescale_auroral,$
  timescale_transport=timescale_transport,$
  atm_model_version=atm_model_version,$
  custom_spectrum=custom_spectrum,$
  no_cache=no_cache

  ; set keyword flags
  no_cache_flag = 0
  if keyword_set(no_cache) then no_cache_flag = 1

  ; convert all output flags to booleans
  foreach value, output_flags, key do begin
    output_flags[key] = boolean(value)
  endforeach

  ; set params
  request_hash = hash()
  request_hash['timestamp'] = time_stamp
  request_hash['geodetic_latitude'] = geo_lat
  request_hash['geodetic_longitude'] = geo_lon
  request_hash['output'] = output_flags
  if (no_cache_flag eq 1) then request_hash['no_cache'] = boolean(1)
  if (isa(maxwellian_energy_flux) eq 1) then request_hash['maxwellian_energy_flux'] = maxwellian_energy_flux
  if (isa(gaussian_energy_flux) eq 1) then request_hash['gaussian_energy_flux'] = gaussian_energy_flux
  if (isa(maxwellian_characteristic_energy) eq 1) then request_hash['maxwellian_characteristic_energy'] = maxwellian_characteristic_energy
  if (isa(gaussian_peak_energy) eq 1) then request_hash['gaussian_peak_energy'] = gaussian_peak_energy
  if (isa(gaussian_spectral_width) eq 1) then request_hash['gaussian_spectral_width'] = gaussian_spectral_width
  if (isa(nrlmsis_model_version) eq 1) then request_hash['nrlmsis_model_version'] = nrlmsis_model_version
  if (isa(oxygen_correction_factor) eq 1) then request_hash['oxygen_correction_factor'] = oxygen_correction_factor
  if (isa(timescale_auroral) eq 1) then request_hash['timescale_auroral'] = timescale_auroral
  if (isa(timescale_transport) eq 1) then request_hash['timescale_transport'] = timescale_transport
  if (isa(atm_model_version) eq 1) then request_hash['atm_model_version'] = atm_model_version
  if (isa(custom_spectrum) eq 1) then request_hash['custom_spectrum'] = custom_spectrum

  ; create post struct and serialize into a string
  post_str = json_serialize(request_hash,/lowercase)

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.phys.ucalgary.ca'
  req->SetProperty,URL_PATH = 'api/v1/atm/forward'
  req->SetProperty,HEADERS = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

  ; make request
  output = req->Put(post_str, /BUFFER, /STRING_ARRAY, /POST)

  ; get status code and get response headers
  req->GetProperty,RESPONSE_CODE=status_code,RESPONSE_HEADER=response_headers

  ; cleanup this request
  obj_destroy,req

  ; check status code
  if (status_code ne 200) then begin
    if (verbose eq 1) then print,'[aurorax_atm_forward] Error performing calculatoin: ' + output
    return,!NULL
  endif

  ; serialize into dictionary
  data = json_parse(output,/dictionary)

  ; serialize any List() objects to float arrays
  foreach value, data['data'], key do begin
    if (isa(value, 'List') eq 1) then begin
      data['data',key] = value.toArray(type='float')
    endif
  endforeach

  ; finally convert to struct
  data = data.toStruct(/recursive)

  ; return
  return,data
end