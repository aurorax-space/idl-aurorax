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

pro aurorax_example_atm_forward
  ; --------------------------------
  ; TREx ATM forward calculations
  ; --------------------------------
  ;
  ; TREx-ATM is a time-dependent Aurora Transport Model (ATM), designed to leverage and support TREx optical
  ; data. TREx-ATM uses the two-stream electron transport code embedded in the GLOW model (Solomon et al., 1988)
  ; with ambipolar diffusion to compute the electron transport. It has additional capacity to compute impact
  ; ionization, secondary electron production, and impact excitation of neutrals (height resolved).
  ;
  ; Use of the TREx-ATM model should cite:
  ;
  ; - Liang, J., Donovan, E., Jackel, B., Spanswick, E., & Gillies, M. (2016). On the 630nmred-linepulsating aurora:
  ; Red-line emission geospace observatory observations and model simulations. Journal of Geophysical Research: Space
  ; Physics, 121, 7988–8012. https://doi.org/10.1002/2016JA022901
  ; - Liang, J., Yang, B., Donovan, E., Burchill, J., & Knudsen, D. (2017). Ionospheric electron heating associated
  ; with pulsating auroras: A Swarm survey and model simulation. Journal of Geophysical Research: Space Physics, 122,
  ; 8781–8807. https://doi.org/10.1002/2017JA024127

  ; --------------------------------
  ; Perform a basic 'forward' calculation
  ; --------------------------------
  ;
  ; First will show how to do a basic request, and plot the results.
  ;
  ; Requests take a series of input parameters. Some parameters are required, and some are optional with default values
  ; that will be set if they are not supplied. The following request we'll be performing utilizes all default values for
  ; the optional parameter (marked as such with a comment on that line).
  ;
  ; ATM requests require that users toggle ON outputs they wish to have returned. This allows you to get back only what
  ; you want. This mechanism is controlled by the `aurorax_atm_forward_get_output_flags()` function that should be created
  ; before making an ATM calculation.

  ; As part of this function, there are keywords that toggle ON or OFF all outputs, and toggle on common groups.
  ;
  ; More details on usage of the `aurorax_atm_forward()` function can be found the function's documentation.
  aurorax_example_atm_forward1

  ; --------------------------------
  ; Forward calculation and include all output parameters
  ; --------------------------------
  ;
  ; You can also do a request and specify the output flags to return everything that the ATM 'forward' endpoint has
  ; to offer. Below, we're going to do that and plot all data.
  aurorax_example_atm_forward2
end

pro aurorax_example_atm_forward1
  ; Below we will do a simple ATM forward calculation
  ;
  ; set the location (Calgary-ish)
  ;
  ; NOTE: ATM forward calculations can be performed for any latitude or longitude (this is NOT the case
  ; for ATM inverse calculations; limitations on location and time exist for that function).
  latitude = 51.04
  longitude = -114.05

  ; set the timestamp to UT06 of the previous day
  ;
  ; NOTE: ATM forward calculations can be performed for any date up to the end of the previous day. It
  ; is expected to be in UTC time.
  time_stamp = '2024-01-01T06:00:00'

  ; set up our output flags
  ;
  ; NOTE: all output parameters are default to False. Here we initialize the output flags we want
  ; to get we'll ask for the basic information - just the height-integrated rayleighs values
  output_flags = aurorax_atm_forward_get_output_flags(/enable_only_height_integrated_rayleighs) ; initialize output flags, all will be False by default
  output_flags['altitudes'] = 1 ; enable altitudes
  output_flags['emission_5577'] = 1 ; enable 5577 emission

  ; make the request
  print, '[Simple example] Performing calculation'
  data = aurorax_atm_forward(time_stamp, latitude, longitude, output_flags, atm_model_version='1.0')
  print, '[Simple example] Calculation received'

  ; print results
  help, data
  print, ''
  
  ; print the information we asked for
  print, 'Height-integrated Rayleighs:'
  print, '  427.8nm: ' + strcompress(string(data.data.height_integrated_rayleighs_4278))
  print, '  557.7nm: ' + strcompress(string(data.data.height_integrated_rayleighs_5577))
  print, '  630.0nm: ' + strcompress(string(data.data.height_integrated_rayleighs_6300))
  print, '  844.6nm: ' + strcompress(string(data.data.height_integrated_rayleighs_8446))
  print, '  LBH:     ' + strcompress(string(data.data.height_integrated_rayleighs_lbh))
  print, '  130.4nm: ' + strcompress(string(data.data.height_integrated_rayleighs_1304))
  print, '  135.6nm: ' + strcompress(string(data.data.height_integrated_rayleighs_1356))

end

pro aurorax_example_atm_forward2
  ; do a ATM forward request and get ALL output values back
  ;
  ; set up params
  time_stamp = '2021-11-04T06:00:00'
  latitude = 58.227808
  longitude = -103.680631

  ; set output flags
  output_flags = aurorax_atm_forward_get_output_flags(/set_all_true)

  ; make the request
  result = aurorax_atm_forward(time_stamp, latitude, longitude, output_flags)

  ; show results
  data = result.data
  help, data
  
  ; Let's plot the data that we got back
  w = window(dimensions=[400,700], location=[0,0])
  alt = data.altitudes
  
  ; Plot all of the emissions as a column of subplots
  p_1304 = plot(alt, data.emission_1304, name='130.4 nm', color='purple', layout=[1,6,1], /current, margin=[0.325,0.25,0.1,0.05], thick=3)
  p_1356 = plot(alt, data.emission_1356, name='135.6 nm', color='hot pink', /overplot, xrange=[80,500], margin=[0.325,0.25,0.1,0.05], thick=3)
  p_blue = plot(alt, data.emission_4278, name='427.8 nm', color='dodger blue', layout=[1,6,2], /current, xrange=[80,500], margin=[0.325,0.25,0.1,0.05], thick=3)
  p_green = plot(alt, data.emission_5577, name='557.7 nm', color='green', layout=[1,6,3], /current, xrange=[80,500], margin=[0.325,0.25,0.1,0.05], thick=3)
  p_red = plot(alt, data.emission_6300, name='630.0 nm', color='crimson', layout=[1,6,4], /current, xrange=[80,500], margin=[0.325,0.25,0.1,0.05], thick=3)
  p_nir = plot(alt, data.emission_8446, name='844.6 nm', color='blue violet', layout=[1,6,5], /current, xrange=[80,500], margin=[0.325,0.25,0.1,0.05], thick=3)
  p_lbh = plot(alt, data.emission_lbh, name='LBH', color='indigo', layout=[1,6,6], /current, xrange=[80,500], margin=[0.325,0.25,0.1,0.05], thick=3)
  p_green.ytitle = 'Volume Emission Rate (cm$^{-3}$ s$^{-1}$)'
  p_lbh.xtitle = 'Altitude (km)'
  
  ; Add a legend
  l = legend(target=[p_1304, p_1356, p_blue, p_green, p_red, p_nir, p_lbh], position=[0.225,0.4], /normal, color='white', sample_width=0.05)
  
  ; Plot the plasma densities
  w = window(dimensions=[500,250], location=[425,0])
  p_e_density = plot(alt, data.plasma_electron_density, name='Electron', color='green', /current, thick=3)
  p_o2_density = plot(alt, data.plasma_o2plus_density, name='O$^{2+}$', color='black', /overplot, thick=3)
  p_no_density = plot(alt, data.plasma_noplus_density, name='NO$^{+}$', color='blue', /overplot, thick=3)
  p_o_density = plot(alt, data.plasma_oplus_density, name='O$^{+}$', color='red', /overplot, xrange=[80,600], thick=3)
  p_e_density.ytitle = 'Plasma Density (cm$^{-3}$)'
  p_e_density.xtitle = 'Altitude (km)'
  p_e_density.title = 'Plasma Density'
  l = legend(target=[p_e_density, p_o2_density, p_no_density, p_o_density], position=[0.8,0.8], /normal, color='white')
  
  ; Plot plasma ionisation rate
  w = window(dimensions=[500,250], location=[425,325])
  p_ion_rate = plot(alt, data.plasma_ionisation_rate, title='Plasma Ionization Rate', color='black', /current, thick=3, $
                    ytitle='Ionization Rate (cm$^{-3} \cdot $s$^{-1}$)', xtitle='Altitude (km)')
  
  ; Plot electron and ion temperatures
  w = window(dimensions=[500,250], location=[425,650])
  p_e_temp = plot(alt, data.plasma_electron_temperature, title='Plasma Temperature', name='Ion Temp.', color='blue', /current, thick=3, ytitle='Temperature (K)')
  p_ion_temp = plot(alt, data.plasma_ion_temperature, name='Electron Temp.', color='red', /overplot, thick=3, xrange=[80,800], xtitle='Altitude (km)')
  l = legend(target=[p_e_temp, p_ion_temp], position=[0.8,0.8], /normal, color='white')
  
  ; Plot plasma conductivities
  w = window(dimensions=[500,250], location=[925,0])
  p_pederson = plot(alt, data.plasma_pederson_conductivity, title='Conductivities', name='Pederson', color='green', /current, thick=3, ytitle='Conductivity (S/m)')
  p_hall = plot(alt, data.plasma_hall_conductivity, name='Hall', color='black', /overplot, thick=3, xrange=[80,250], xtitle='Altitude (km)')
  l = legend(target=[p_pederson, p_hall], position=[0.8,0.8], /normal, color='white')
  
  ; Plot plasma production rates
  w = window(dimensions=[500,250], location=[925,325])
  p_n_prod = plot(alt, data.production_rate_n, title='Production Rates', name='N Production Rate', color='red', /current, thick=3, ytitle='Production Rate (1/cm$^3$/s)')
  p_nplus_prod = plot(alt, data.production_rate_nplus, name='N$^+$ Production Rate', color='blue', /overplot, thick=3, xrange=[80,250], xtitle='Altitude (km)')
  l = legend(target=[p_n_prod, p_nplus_prod], position=[0.8,0.8], /normal, color='white')
  
end
