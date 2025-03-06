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
;       Perform TREx Auroral Transport Model (ATM) 'inverse' calculations.
;
;       Perform an inverse calculation using the TREx Auroral Transport Model
;       and the supplied input parameters. Note that this function utilizes the
;       UCalgary Space Remote Sensing API to perform the calculation.
;
; :Parameters:
;       time_stamp: in, required, String
;         Timestamp in UTC, format must be YYYY-MM-DDTHH:MM:SS.
;       geo_lat: in, required, Float
;         Latitude in geodetic coordinates. Currently limited to the Transition Region Explorer
;         (TREx) region of >=50.0 and <61.5 degrees. An error will be raised if outside of this range.
;       geo_lon: in, required, Float
;         Longitude in geodetic coordinates. Currently limited to the Transition Region Explorer
;         (TREx) region of >=-110 and <-70 degrees. An error will be raised if outside of this range.
;       intensity_4278: in, required, Float
;         Intensity of the 427.8nm (blue) wavelength in Rayleighs.
;       intensity_5577: in, required, Float
;         Intensity of the 557.7nm (green) wavelength in Rayleighs.
;       intensity_6300: in, required, Float
;         Intensity of the 630.0nm (red) wavelength in Rayleighs.
;       intensity_8446: in, required, Float
;         Intensity of the 844.6nm (near infrared) wavelength in Rayleighs.
;       output_flags: in, required, Hash
;         Flags to indicate which values are included in the output, generated
;         using the aurorax_atm_forward_get_output_flags() function.
;
; :Keywords:
;       precipitation_flux_spectral_type: in, optional, String
;         The precipitation flux spectral type to use. Possible values are gaussian or maxwellian. The default is gaussian.
;       nrlmsis_model_version: in, optional, String
;         NRLMSIS version number. Possible values are 00 or 2.0. Default is 2.0.
;       atmospheric_attenuation_correction: in, optional, Integer
;         Apply an atmospheric attenuation correction factor. Default is 0. Set to 1 to enable.
;       atm_model_version: in, optional, String
;         ATM model version number. Possible values are only '1.0' at this time, but will have additional possible values in the future.
;       no_cache: in, optional, Boolean
;         The UCalgary Space Remote Sensing API utilizes a caching layer for performing ATM
;         calculations. If this variation of input parameters has been run before (and the
;         cache is still valid), then it will not re-run the calculation. Instead it will
;         return the cached results immediately. To disable the caching layer, use this keyword.
;
; :Returns:
;       Struct
;
; :Examples:
;       Refer to examples directory, or data.phys.ucalgary.ca
;+
function aurorax_atm_inverse, $
  time_stamp, $
  geo_lat, $
  geo_lon, $
  intensity_4278, $
  intensity_5577, $
  intensity_6300, $
  intensity_8446, $
  output_flags, $
  precipitation_flux_spectral_type = precipitation_flux_spectral_type, $
  nrlmsis_model_version = nrlmsis_model_version, $
  atmospheric_attenuation_correction = atmospheric_attenuation_correction, $
  atm_model_version = atm_model_version, $
  no_cache = no_cache
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
  if (isa(intensity_4278) eq 1) then request_hash['intensity_4278'] = intensity_4278
  if (isa(intensity_5577) eq 1) then request_hash['intensity_5577'] = intensity_5577
  if (isa(intensity_6300) eq 1) then request_hash['intensity_6300'] = intensity_6300
  if (isa(intensity_8446) eq 1) then request_hash['intensity_8446'] = intensity_8446
  if (isa(precipitation_flux_spectral_type) eq 1) then request_hash['precipitation_flux_spectral_type'] = precipitation_flux_spectral_type
  if (isa(nrlmsis_model_version) eq 1) then request_hash['nrlmsis_model_version'] = nrlmsis_model_version
  if (isa(atmospheric_attenuation_correction) eq 1) then request_hash['atmospheric_attenuation_correction'] = atmospheric_attenuation_correction
  if (isa(atm_model_version) eq 1) then request_hash['atm_model_version'] = atm_model_version

  ; create post struct and serialize into a string
  post_str = json_serialize(request_hash, /lowercase)

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.phys.ucalgary.ca'
  req.setProperty, url_path = 'api/v1/atm/inverse'
  req.setProperty, headers = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

  ; make request
  r = __aurorax_perform_api_request('post', 'aurorax_atm_forward', req, post_str = post_str)
  if (r.status_code ne 200) then return, !null
  output = r.output

  ; get status code and get response headers
  r.req.getProperty, response_code = status_code

  ; cleanup this request
  obj_destroy, req

  ; check status code
  if (status_code ne 200) then begin
    print, '[aurorax_atm_inverse] Error performing calculation: ' + output
    return, !null
  endif

  ; serialize into dictionary
  data = json_parse(output, /dictionary)

  ; serialize any List() objects to float arrays
  foreach value, data['data'], key do begin
    if (isa(value, 'List') eq 1) then begin
      data['data', key] = value.toArray(type = 'float')
    endif
  endforeach

  ; finally convert to struct
  data = data.toStruct(/recursive)

  ; return
  return, data
end
