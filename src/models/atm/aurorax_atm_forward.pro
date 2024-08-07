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

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_ATM_FORWARD
;
; PURPOSE:
;       Perform TREx Auroral Transport Model (ATM) 'forward' calculations.
;
; EXPLANATION:
;       Perform a forward calculation using the TREx Auroral Transport Model
;       and the supplied input parameters. Note that this function utilizes the
;       UCalgary Space Remote Sensing API to perform the calculation.
;
;       The ATM model is 1D and time-independent. However, the optional parameters
;       timescale_auroral and timescale_transport provide limited support for time-dependent
;       and transport process. The timescale_auroral parameter (T0) is the duration
;       of the precipitation. The timescale_transport parameter is defined by L/v0,
;       in which L is the dimension of the auroral structure, and v0 is the cross-structure
;       drift speed. The model quasi-analytically solves the continuity equation under
;       a square input (with time duration T0 and spatial width L) input of precipitation.
;       The initial/boundary conditions are given by IRI. The output yields the mean
;       density/VER over [0-L] at time T0.
;
; CALLING SEQUENCE:
;       aurorax_atm_forward(time_stamp,geo_lat,geo_lon,output_flags,...)
;
; PARAMETERS:
;       time_stamp                          Timestamp in UTC, format must be YYYY-MM-DDTHH:MM:SS. Required
;       geo_lat                             Latitude in geodetic coordinates: -90.0 to 90.0. Required
;       geo_lon                             Longitude in geodetic coordinates: -180.0 to 180.0. Required
;       output_flags                        Flags to indictate which values are included in the output, generated
;                                           using the aurorax_atm_forward_get_output_flags() function. Required
;       maxwellian_energy_flux              Maxwellian energy flux in erg/cm2/s. Default is 10. This parameter is optional.
;       gaussian_energy_flux                Gaussian energy flux in erg/cm2/s. Default is 0.0. Note that gaussian_peak_energy 
;                                             and gaussian_spectral_width must be specified if the gaussian_energy_flux is not 
;                                             0. This parameter is optional.
;       maxwellian_characteristic_energy    Maxwellian characteristic energy in eV. Default is 5000. Note that maxwellian_characteristic_energy 
;                                             must be specified if the maxwellian_energy_flux is not 0. This parameter is optional.
;       gaussian_peak_energy                Gaussian peak energy in eV. Default is 1000. Note this parameter must be specified 
;                                             if the gaussian_energy_flux is not 0. This parameter is optional.
;       gaussian_spectral_width             Gaussian spectral width in eV. Default is 100. Note this parameter must be specified 
;                                             if the gaussian_energy_flux is not 0. This parameter is optional.
;       nrlmsis_model_version               NRLMSIS version number. Possible values are 00 or 2.0. Default is 2.0. This parameter 
;                                             is optional. More details about this empirical model can be found here, and here.
;       oxygen_correction_factor            Oxygen correction factor used to multiply by in the empirical model. Default is 1. 
;                                             This parameter is optional.
;       timescale_auroral                   The duration of the precipitation, in seconds. Default is 600 (10 minutes). This 
;                                             parameter is optional.
;       timescale_transport                 Defined by L/v0, in which L is the dimension of the auroral structure, and v0 is 
;                                             the cross-structure drift speed. Represented in seconds. Default is 600 (10 minutes). 
;                                             This parameter is optional.
;       atm_model_version                   ATM model version number. Possible values are only '1.0' at this time, but will have 
;                                             additional possible values in the future. This parameter is optional.
;       custom_spectrum                     A struct containing two 1D float arrays. One array containing values representing the 
;                                             energy in eV, and another representing flux in 1/cm2/sr/eV. Note that this array 
;                                             cannot contain negative values. This parameter is optional.
;
; KEYWORDS:
;       /NO_CACHE         The UCalgary Space Remote Sensing API utilizes a caching layer for performing ATM 
;                         calculations. If this variation of input parameters has been run before (and the 
;                         cache is still valid), then it will not re-run the calculation. Instead it will 
;                         return the cached results immediately. To disable the caching layer, use this keyword.
;
; OUTPUT
;       Calculated results
;
; OUTPUT TYPE:
;       a struct
;
; EXAMPLES:
;       Refer to examples directory, or data.phys.ucalgary.ca
;+
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
    print,'[aurorax_atm_forward] Error performing calculatoin: ' + output
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