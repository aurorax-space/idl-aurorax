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
;       Perform TREx Auroral Transport Model (ATM) 'forward' calculations.
;
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
; :Parameters:
;       time_stamp: in, required, String
;         Timestamp in UTC, format must be YYYY-MM-DDTHH:MM:SS.
;       geo_lat: in, required, Float
;         Latitude in geodetic coordinates: -90.0 to 90.0.
;       geo_lon: in, required, Float
;         Longitude in geodetic coordinates: -180.0 to 180.0.
;       output_flags: in, required, Hash
;         Flags to indicate which values are included in the output, generated
;         using the aurorax_atm_forward_get_output_flags() function.
;
; :Keywords:
;       maxwellian_energy_flux: in, optional, Float
;         Maxwellian energy flux in erg/cm2/s. Default is 10.
;       gaussian_energy_flux: in, optional, Float
;         Gaussian energy flux in erg/cm2/s. Default is 0.0. Note that gaussian_peak_energy
;         and gaussian_spectral_width must be specified if the gaussian_energy_flux is not 0.
;       maxwellian_characteristic_energy: in, optional, Float
;         Maxwellian characteristic energy in eV. Default is 5000. Note that maxwellian_characteristic_energy
;         must be specified if the maxwellian_energy_flux is not 0.
;       gaussian_peak_energy: in, optional, Float
;         Gaussian peak energy in eV. Default is 1000. Note this parameter must be specified
;         if the gaussian_energy_flux is not 0.
;       gaussian_spectral_width: in, optional, Float
;         Gaussian spectral width in eV. Default is 100. Note this parameter must be specified
;         if the gaussian_energy_flux is not 0.
;       kappa_energy_flux: in, optional, Float
;         Kappa energy flux in erg/cm2/s. Default is 0, meaning all kappa parameters will be disabled. Note that
;         `kappa_mean_energy` and `kappa_k_index` should be specified if `kappa_energy_flux` is not 0. If they are not, then
;         their defaults will be used. This parameter is optional.
;       kappa_mean_energy: in, optional, Float
;         Kappa mean energy in eV. Default is 30000. Note this parameter should be specified if the `kappa_energy_flux`
;         is not 0. This parameter is optional.
;       kappa_k_index: in, optional, Float
;         Kappa k-index. Default is 5. Note this parameter should be specified if the `kappa_energy_flux` is not 0. This
;         parameter is optional.
;       exponential_energy_flux: in, optional, Float
;         Exponential energy flux, in erg/cm2/s. Default is 0, meaning all exponential parameters will be disabled. Note that
;         `exponential_characteristic_energy` and `exponential_starting_energy` should be specified if `exponential_energy_flux`
;         is not 0. If it is not, then the default will be used. This parameter is optional.
;       exponential_characteristic_energy: in, optional, Float
;         Exponential characteristic energy, in eV. Default is 50000. Note this parameter should be specified if the
;         `exponential_energy_flux` is not 0. This parameter is optional.
;       exponential_starting_energy: in, optional, Float
;         Exponential starting energy, in eV. Default is 50000. Note this parameter should be specified if the
;         `exponential_energy_flux` is not 0. This parameter is optional.
;       proton_energy_flux: in, optional, Float
;         Proton energy flux, in erg/cm2/s. Default is 0, meaning all proton parameters will be disabled. Note that
;         `proton_characteristic_energy` should be specified if `proton_energy_flux` is not 0. If it is not, then the default
;         will be used. This parameter is optional.
;       proton_characteristic_energy: in, optionial, Float
;         Proton characteristic energy, in eV. Default is 10000. Not this parameter should be specified if the
;         `proton_energy_flux` is not 0. This parameter is optional.
;       d_region: in, optional, Boolean
;         Flag to enable D-region evaluation. Default is False.
;       nrlmsis_model_version: in, optional, String
;         NRLMSIS version number. Possible values are 00 or 2.0. Default is 2.0.
;       oxygen_correction_factor: in, optional, Float
;         Oxygen correction factor used to multiply by in the empirical model. Default is 1.
;       timescale_auroral: in, optional, Float
;         The duration of the precipitation, in seconds. Default is 600 (10 minutes).
;       timescale_transport: in, optional, Float
;         Defined by L/v0, in which L is the dimension of the auroral structure, and v0 is
;         the cross-structure drift speed. Represented in seconds. Default is 600 (10 minutes).
;       atm_model_version: in, optional, String
;         ATM model version number. Possible values are '2.0'. Default is '2.0'.
;       custom_spectrum: in, optional, Struct
;         A struct containing two 1D float arrays. One array containing values representing the
;         energy in eV, and another representing flux in 1/cm2/sr/eV. Note that this array
;         cannot contain negative values.
;       custom_neutral_profile: in, optional, Float
;         A 2-dimensional float array containing values representing the energy in eV, and flux
;         in 1/cm2/sr/eV. The shape is expected to be [N, 2], with energy in [*, 0] and flux
;         in [*, 1].
;         Note that this array cannot contain negative values (API Error
;         will be raised if so). This parameter is optional.
;         Users are responsible for fully covering the altitude range of interest in the
;         provided profile (80-800 km if d_region_flag=0, or 50-500 km if d_region_flag=1). The
;         model only performs interpolation, not extrapolation.
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
function aurorax_atm_forward, $
  time_stamp, $
  geo_lat, $
  geo_lon, $
  output_flags, $
  maxwellian_energy_flux = maxwellian_energy_flux, $
  maxwellian_characteristic_energy = maxwellian_characteristic_energy, $
  gaussian_energy_flux = gaussian_energy_flux, $
  gaussian_peak_energy = gaussian_peak_energy, $
  gaussian_spectral_width = gaussian_spectral_width, $
  kappa_energy_flux = kappa_energy_flux, $
  kappa_mean_energy = kappa_mean_energy, $
  kappa_k_index = kappa_k_index, $
  exponential_energy_flux = exponential_energy_flux, $
  exponential_characteristic_energy = exponential_characteristic_energy, $
  exponential_starting_energy = exponential_starting_energy, $
  proton_energy_flux = proton_energy_flux, $
  proton_characteristic_energy = proton_characteristic_energy, $
  d_region = d_region, $
  nrlmsis_model_version = nrlmsis_model_version, $
  oxygen_correction_factor = oxygen_correction_factor, $
  timescale_auroral = timescale_auroral, $
  timescale_transport = timescale_transport, $
  atm_model_version = atm_model_version, $
  custom_spectrum = custom_spectrum, $
  custom_neutral_profile = custom_neutral_profile, $
  no_cache = no_cache
  ; set keyword flags
  no_cache_flag = 0
  if keyword_set(no_cache) then no_cache_flag = 1

  ; convert all output flags to booleans
  foreach value, output_flags, key do begin
    output_flags[key] = boolean(value)
  endforeach

  ; default to model version 2.0
  if (not isa(atm_model_version)) then begin
    atm_model_version = '2.0'
  endif

  ; check that no version 2.0 params were passed if version 1.0 was requested
  if (atm_model_version eq '1.0') then begin
    print, '[aurorax_atm_forward] Error : ATM model version 1.0 is no longer supported'
    return, !null
  endif else if (atm_model_version eq '2.0') then begin
    url_version_str = 'v2'
  endif else begin
    print, '[aurorax_atm_forward] Error : ATM model version ' + atm_model_version + ' is not currently accepted.'
    return, !null
  endelse

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
  if (isa(custom_spectrum) eq 1) then request_hash['custom_spectrum'] = custom_spectrum
  if (isa(kappa_energy_flux) eq 1) then request_hash['kappa_energy_flux'] = kappa_energy_flux
  if (isa(kappa_mean_energy) eq 1) then request_hash['kappa_mean_energy'] = kappa_mean_energy
  if (isa(kappa_k_index) eq 1) then request_hash['kappa_k_index'] = kappa_k_index
  if (isa(exponential_energy_flux) eq 1) then request_hash['exponential_energy_flux'] = exponential_energy_flux
  if (isa(exponential_characteristic_energy) eq 1) then request_hash['exponential_characteristic_energy'] = exponential_characteristic_energy
  if (isa(exponential_starting_energy) eq 1) then request_hash['exponential_starting_energy'] = exponential_starting_energy
  if (isa(proton_energy_flux) eq 1) then request_hash['proton_energy_flux'] = proton_energy_flux
  if (isa(proton_characteristic_energy) eq 1) then request_hash['proton_characteristic_energy'] = proton_characteristic_energy
  if (isa(d_region) eq 1) then request_hash['d_region'] = d_region

  if (isa(custom_neutral_profile) eq 1) then begin
    custom_neutral_profile_hash = hash('altitude', reform(custom_neutral_profile[0, *]), $
      'o_density', reform(custom_neutral_profile[1, *]), $
      'o2_density', reform(custom_neutral_profile[2, *]), $
      'n2_density', reform(custom_neutral_profile[3, *]), $
      'n_density', reform(custom_neutral_profile[4, *]), $
      'no_density', reform(custom_neutral_profile[5, *]), $
      'temperature', reform(custom_neutral_profile[6, *]))

    request_hash['custom_neutral_profile'] = custom_neutral_profile_hash
  endif

  ; create post struct and serialize into a string
  post_str = json_serialize(request_hash, /lowercase)

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.phys.ucalgary.ca'
  req.setProperty, url_path = 'api/' + url_version_str + '/atm/forward'
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
    print, '[aurorax_atm_forward] Error performing calculation: ' + output
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
