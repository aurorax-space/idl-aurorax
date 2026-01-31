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
  ; --------------------------------
  ; TREx ATM inverse calculations
  ; --------------------------------
  ;
  ; Using ATM you can also perform inversion calculations to derive various outputs using emission
  ; intensities as inputs.
  ;
  ; This function works very similarly to the 'forward' function, where-by some inputs are required,
  ; some are optional, and outputs are enabled using True/False flags as part of the request.
  ;
  ; Please note that the limitations on latitude and longitude range are designed to constrain requests
  ; to the targeted region that the TREx optical instrumentation are deployed to. It has also been extended
  ; to include the Poker Flat region to help with usages of instrumentation nearby that location. We also
  ; note that the model only takes into account data when the optical instruments were operating at 105
  ; degrees solar zenith angle, which is several degrees lower than nominal data acquisition. This ultimately
  ; means that the beginning and end of each night have been excluded when deriving the model algorithm.
  ;
  ; More details on usage of the `aurorax_atm_inverse()` function can be found the function's documentation.
  aurorax_example_atm_inverse1

  ; --------------------------------
  ; Inverse calculation and include all output parameters
  ; --------------------------------
  ;
  ; We can also do a request and specify the output flags to return everything that the ATM 'inverse'
  ; endpoint has to offer. Below, we're going to do that and plot all data.
  ;
  ; For this request, we're going to also change the precipitation flux spectral type to maxwellian, to
  ; illustrate that either 'gaussian' or 'maxwellian' can be used.
  aurorax_example_atm_inverse2

  ; --------------------------------
  ; Inverse calculation and pass results back into a forward calculation
  ; --------------------------------
  ;
  ; Lastly, we can do an inversion calculation and then feed the results back into the forward routine.
  aurorax_example_atm_inverse3
end

pro aurorax_example_atm_inverse1
  ; Below we will do a simple ATM inverse calculation
  ;
  ; set up our output flags
  ;
  ; NOTE: just like the forward function, outputs are toggled on/off using a flag variable
  output_flags = aurorax_atm_inverse_get_output_flags()
  output_flags['energy_flux'] = 1
  output_flags['mean_energy'] = 1

  ; we'll ask for the basic information: energy flux, mean energy, and oxygen correction factor
  time_stamp = '2021-11-04T06:00:00'
  latitude = 58.227808
  longitude = -103.680631

  ; set our input intensities for several wavelengths
  intensity_4278 = 2302.6
  intensity_5577 = 11339.5
  intensity_6300 = 528.3
  intensity_8446 = 427.4

  ; make the request
  print, '[Simple example] Performing calculation'
  data = aurorax_atm_inverse( $
    time_stamp, $
    latitude, $
    longitude, $
    intensity_4278, $
    intensity_5577, $
    intensity_6300, $
    intensity_8446, $
    output_flags)
  print, '[Simple example] Calculation received'

  ; print results
  help, data
  print, ''

  ; print the information we asked for
  print, 'Energy Flux:              ' + strcompress(string(data.data.energy_flux)) + ' erg/cm2/s'
  print, 'Mean Energy:              ' + strcompress(string(data.data.mean_energy)) + ' eV'
  print, ''
end

pro aurorax_example_atm_inverse2
  ; do a ATM inverse request and get ALL output values back
  ;
  ; set output flags
  output_flags = aurorax_atm_inverse_get_output_flags(/set_all_true)

  ; set up time and location
  time_stamp = '2021-11-04T06:00:00'
  latitude = 58.227808
  longitude = -103.680631

  ; set our input intensities for several wavelengths
  intensity_4278 = 2302.6
  intensity_5577 = 11339.5
  intensity_6300 = 528.3
  intensity_8446 = 427.4

  ; make the request
  print, '[All output example] Performing calculation'
  data = aurorax_atm_inverse( $
    time_stamp, $
    latitude, $
    longitude, $
    intensity_4278, $
    intensity_5577, $
    intensity_6300, $
    intensity_8446, $
    precipitation_flux_spectral_type = 'maxwellian', $ 
    output_flags)
  print, '[All output example] Calculation received'

  ; show results
  help, data.data
end

pro aurorax_example_atm_inverse3
  ; set up ATM inversion request
  output_flags = aurorax_atm_inverse_get_output_flags(/set_all_true)
  time_stamp = '2021-11-04T06:00:00'
  latitude = 58.227808
  longitude = -103.680631
  intensity_4278 = 2302.6
  intensity_5577 = 11339.5
  intensity_6300 = 528.3
  intensity_8446 = 427.4

  ; make the inversion request
  print, '[Inverse->forward example] Performing inversion calculation'
  data = aurorax_atm_inverse( $
    time_stamp, $
    latitude, $
    longitude, $
    intensity_4278, $
    intensity_5577, $
    intensity_6300, $
    intensity_8446, $
    precipitation_flux_spectral_type = 'maxwellian', $
    output_flags)
  print, '[Inverse->forward example] Inversion results received'
  help, data.data

  ; set up ATM forward request
  latitude = 51.04
  longitude = -114.05
  time_stamp = '2024-01-01T06:00:00'
  output_flags = aurorax_atm_forward_get_output_flags(/enable_only_height_integrated_rayleighs) ; initialize output flags, all will be False by default

  ; make the forward request
  print, '[Inverse->forward example] Performing forward calculation'
  data = aurorax_atm_forward($
    time_stamp, $
    latitude, $
    longitude, $
    output_flags, $
    maxwellian_energy_flux=data.data.energy_flux, $
    maxwellian_characteristic_energy=data.data.mean_energy)
  print, '[Inverse->forward example] Forward results received'
  
  ; print the information we asked for
  print, 'Height-integrated Rayleighs:'
  print, '  427.8nm:        ' + strcompress(string(data.data.height_integrated_rayleighs_4278))
  print, '  557.7nm:        ' + strcompress(string(data.data.height_integrated_rayleighs_5577))
  print, '  630.0nm:        ' + strcompress(string(data.data.height_integrated_rayleighs_6300))
  print, '  844.6nm:        ' + strcompress(string(data.data.height_integrated_rayleighs_8446))
  print, '  130.4nm:        ' + strcompress(string(data.data.height_integrated_rayleighs_1304))
  print, '  135.6nm:        ' + strcompress(string(data.data.height_integrated_rayleighs_1356))
  print, '  SMILE UVI LBH:  ' + strcompress(string(data.data.height_integrated_rayleighs_smile_uvi_lbh))
end
