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
  ; Introduction
  ; --------------------------------
  ;
  ; Using ATM you can also perform inversion calculations to derive various outputs using emission
  ; intensities as inputs.
  ;
  ; This function works very similarly to the 'forward' function, where-by some inputs are required,
  ; some are optional, and outputs are enabled using True/False flags as part of the request.
  ;
  ; Please note that the limitations on latitude and longitude range are designed to constrain requests
  ; to the targeted region that the TREx optical instrumentation are deployed to. We also note that the
  ; model only takes into account data when the optical instruments were operating at 105 degrees solar
  ; zenith angle, which is several degrees lower than nominal data acquisition. This ultimately means
  ; that the beginning and end of each night have been excluded when deriving the model algorithm.
  ;
  ; More details on usage of the `aurorax_atm_inverse()` function can be found the function's documentation.
  aurorax_example_atm_inverse1

  ; --------------------------------
  ; Inverse calculation and include all output parameters
  ; --------------------------------
  ;
  ; You can also do a request and specify the output flags to return everything that the ATM 'inverse'
  ; endpoint has to offer. Below, we're going to do that and plot all data.
  ;
  ; For this request, we're going to also change the precipitation flux spectral type to maxwellian, to
  ; illustrate that either 'gaussian' or 'maxwellian' can be used.
  aurorax_example_atm_inverse2
end

pro aurorax_example_atm_inverse1
  ; Below we will do a simple ATM inverse calculation
  ;
  ; set up our output flags
  ;
  ; NOTE: just like the forward function, outputs are toggled on/off using a flag variable
  output_flags = aurorax_atm_inverse_get_output_flags()
  output_flags['energy_flux'] = 1
  output_flags['characteristic_energy'] = 1
  output_flags['oxygen_correction_factor'] = 1

  ; we'll ask for the basic information: energy flux, characteristic energy, and oxygen correction factor
  time_stamp = '2021-10-12T06:00:00'
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
  print, 'Characteristic Energy:    ' + strcompress(string(data.data.characteristic_energy)) + ' eV'
  print, 'Oxygen Correction Factor: ' + strcompress(string(data.data.oxygen_correction_factor))
  print, ''
end

pro aurorax_example_atm_inverse2
  ; do a ATM inverse request and get ALL output values back
  ;
  ; set output flags
  output_flags = aurorax_atm_inverse_get_output_flags(/set_all_true)

  ; set up time and location
  time_stamp = '2021-10-12T06:00:00'
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
    output_flags)
  print, '[All output example] Calculation received'

  ; show results
  help, data.data
end
