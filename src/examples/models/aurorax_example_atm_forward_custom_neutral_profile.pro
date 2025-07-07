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

pro aurorax_example_atm_forward_custom_neutral_profile
  ; --------------------------------------------------------
  ; TREx-ATM Forward Calculation with custom neutral profile
  ; -------------------------------------------------------
  ;
  ; Building off the basic TREx-ATM forward example, we can also perform calculations by supplying a custom
  ; neutral profile. Below, we'll do this using some example data as the neutral profile. The altitudes should
  ; be in kilometers, all densities in cm^-3, and temperature in Kelving. More information can be found in
  ; the documentation for the `aurorax_atm_forward()` function.

  ; Input is a 7 x num_neut array
  ;   - The first row is the altitude (kilometers)
  ;   - The 2nd to 6th rows are the densities of O, O2, N2, N, NO (cm^-3)
  ;   - The 7th row is the neutral temperature (Kelvin)
  n_neut = 16
  custom_neutral_profile_arr = fltarr(7, n_neut)
  for i=0, n_neut-1 do begin
    custom_neutral_profile_arr[0, i] = 50. + i * 50.
    custom_neutral_profile_arr[2, i] = 1e16 * exp(-2. * i)
    custom_neutral_profile_arr[3, i] = 2.5e15 * exp(-2. * i)
    custom_neutral_profile_arr[4, i] = 1e6
    custom_neutral_profile_arr[5, i] = 1e6
    custom_neutral_profile_arr[6, i] = 200. + i * 50.
    
    if (i lt 1) then begin
      custom_neutral_profile_arr[1, i] = 1e9
    endif else begin
      custom_neutral_profile_arr[1, i] = 1e10 * exp(-1. * (i - 1.))
    endelse
  endfor
  
  ; Set up the request
  time_stamp = '2021-11-04T06:00:00'
  latitude = 53.1
  longitude = -107.7

  ; set output flags, let's get back all outputs
  output_flags = aurorax_atm_forward_get_output_flags(/set_all_true)

  ; run model, using our custom neutral profile as input
  result = aurorax_atm_forward(time_stamp, latitude, longitude, output_flags, custom_neutral_profile=custom_neutral_profile_arr)
  data = result.data

  ; print results
  help, data
  print, ''

  ; print the information we asked for
  print, 'Height-integrated Rayleighs:'
  print, '  427.8nm: ' + strcompress(string(data.height_integrated_rayleighs_4278))
  print, '  557.7nm: ' + strcompress(string(data.height_integrated_rayleighs_5577))
  print, '  630.0nm: ' + strcompress(string(data.height_integrated_rayleighs_6300))
  print, '  844.6nm: ' + strcompress(string(data.height_integrated_rayleighs_8446))
  print, '  LBH:     ' + strcompress(string(data.height_integrated_rayleighs_lbh))
  print, '  130.4nm: ' + strcompress(string(data.height_integrated_rayleighs_1304))
  print, '  135.6nm: ' + strcompress(string(data.height_integrated_rayleighs_1356))

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
  l = legend(target=[p_e_temp, p_ion_temp], position=[0.8,0.5], /normal, color='white')

  ; Plot plasma conductivities
  w = window(dimensions=[500,250], location=[925,0])
  p_pederson = plot(alt, data.plasma_pederson_conductivity, title='Conductivities', name='Pederson', color='green', /current, thick=3, ytitle='Conductivity (S/m)')
  p_hall = plot(alt, data.plasma_hall_conductivity, name='Hall', color='black', /overplot, thick=3, xrange=[80,700], xtitle='Altitude (km)')
  l = legend(target=[p_pederson, p_hall], position=[0.8,0.8], /normal, color='white')

  ; Plot plasma production rates
  w = window(dimensions=[500,250], location=[925,325])
  p_n_prod = plot(alt, data.production_rate_n, title='Production Rates', name='N Production Rate', color='red', /current, thick=3, ytitle='Production Rate (1/cm$^3$/s)')
  p_nplus_prod = plot(alt, data.production_rate_nplus, name='N$^+$ Production Rate', color='blue', /overplot, thick=3, xrange=[80,700], xtitle='Altitude (km)')
  l = legend(target=[p_n_prod, p_nplus_prod], position=[0.8,0.8], /normal, color='white')
  
end
