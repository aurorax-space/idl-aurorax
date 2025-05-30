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

pro aurorax_example_get_intensity_from_trex_spectrograph
  
  ; Compute absolute intensity from spectrograph data
  ; 
  ; TREx Spectrograph data allows you to obtain the absolute intensities of known
  ; auroral emissions, such as the 427.8 nm Blueline, the 486.1 nm HBeta, the 557.7 nm
  ; Greenline, or the 630.0 nm Redline emissions. These are obtained via an integration
  ; of the spectra over a known wavelength range (and subtraction of a background
  ; intensity over another known background wavelength range). Alternatively, if you
  ; would like to pull out a different emission, the tools below also have functionality
  ; to manually specify a wavlength range (and optionally a background range).
  ; 
  ; Below are some examples of pulling out different emissions from the spectrograph
  ; data, to simply look at the absolute intensities as a function of time. This
  ; functionality is particularly handy for deriving inputs to the TREx-ATM model
  ; inversion calculation, which requires the absolute intensities of several common
  ; auroral emissions.
  
  
  ; First, read one hour of processed (L1) spectrograph data
  d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', '2021-02-16T09:00', '2021-02-16T09:59', site_uid = 'rabb')
  spect_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; Time and spectrograph bin of interest
  t_0 = '2021-02-16T09:30:00'
  spect_bin = 150

  ; Compute the absolute intensities (in Rayleighs) of four common auroral emissions,
  ; at the above time and location with the spectrograph FoV
  i_4278 = aurorax_spectra_get_intensity(spect_data, t_0, spect_bin, spect_emission='blue')
  i_4861 = aurorax_spectra_get_intensity(spect_data, t_0, spect_bin, spect_emission='hbeta')
  i_5577 = aurorax_spectra_get_intensity(spect_data, t_0, spect_bin, spect_emission='green')
  i_6300 = aurorax_spectra_get_intensity(spect_data, t_0, spect_bin, spect_emission='red')
  
  ; Print the results
  print
  print, 'Absolute Intensities Measured at Spectrograph bin '+strcompress(string(spect_bin),/remove_all)+' for '+t_0+' UTC'
  print, '        Blue-line Intensity: '+strcompress(string(i_4278),/remove_all)+' Rayleighs'
  print, '        H-Beta Intensity: '+strcompress(string(i_4861),/remove_all)+' Rayleighs'
  print, '        Green-line Intensity: '+strcompress(string(i_5577),/remove_all)+' Rayleighs'
  print, '        Red-line Intensity: '+strcompress(string(i_6300),/remove_all)+' Rayleighs'
  print
  
  ; Rather than calculating intensities at a single point in time, you may want to use a time range,
  ; such as one hour of data
  ;
  ; You could manually create a list of timestamps to calculate intensities for, or as is done below,
  ; you can just pass in the timestmap list associated with the data object that was read in
  ; 
  ; To do that the ' UTC' must be removed from the timestamps first
  ts_arr = strmid(spect_data.timestamp, 0, 19)
  
  ; Now just pass the list of timestamps into the aurorax function
  i_5577 = aurorax_spectra_get_intensity(spect_data, ts_arr, spect_bin, spect_emission='green')
  i_6300 = aurorax_spectra_get_intensity(spect_data, ts_arr, spect_bin, spect_emission='red')
  
  ; The result will be a time series of each emission intensity let's create a julian day time axis
  ; that we can use for IDL plotting, and plot the 557.7 and 630.0 nm intensities s a function of time
  julian_ts_arr = julday(fix(strmid(ts_arr,5,2)), fix(strmid(ts_arr,8,2)), fix(strmid(ts_arr,0,4)), $      ; month, day, year
                        fix(strmid(ts_arr,11,2)),  fix(strmid(ts_arr,14,2)),  fix(strmid(ts_arr,17,2)))   ; hour, minute, second
  
  ; Plot the intensities as a function of time
  p_5577 = plot(julian_ts_arr, i_5577, xtickunits='Time', xtickformat='(C(CHI2.2,":",CMI2.2))', color='green', $
                thick=2, xtitle='Time (UTC)', ytitle='Intensity (Rayleighs)', title='TREx-Spectrograph bin 150 (557.7 nm)', $
                dimensions=[800,300], location=[0,0], yrange=[0,40000])
                
  p_6300 = plot(julian_ts_arr, i_6300, xtickunits='Time', xtickformat='(C(CHI2.2,":",CMI2.2))', color='firebrick', $
                thick=2, xtitle='Time (UTC)', ytitle='Intensity (Rayleighs)', title='TREx-Spectrograph bin 150 (630.0 nm)', $
                dimensions=[800,300], location=[0,370], yrange=[0,1500])
  
  
  ; You may want to obtain the absolute intensites of other emissions that are not
  ; recognized among the common auroral emissions included in the aurorax function.
  ;
  ; This can be done simply by supplying manual wavelength ranges for the signal
  ; channel and optionally a background channel, for which spectra will be integrated
  ; over.
  
  ; Looking again at a single point in time
  t_0 = '2021-02-16T09:30:00'
  spect_bin = 150
  
  ; define signal channel
  emission_wavelength_range = [625.0, 635.0] ; nm
  
  ; pass in the wavelength range to integrate over 
  intensity = aurorax_spectra_get_intensity(spect_data, t_0, spect_bin, spect_band_signal=emission_wavelength_range)
  print, 'Absolute Intensity: '+strcompress(string(intensity),/remove_all)+' Rayleighs'
  
  ; Notice the warning that is raised. Oftern, to properly integrate spectrograph data, a background
  ; channel should be substracted, which can be sodne using the spect_bg_band argument.
  emission_wavelength_range = [625.0, 635.0] ; nm
  background_wavelength_range = [640.0, 645.0]  ; nm
  intensity = aurorax_spectra_get_intensity(spect_data, t_0, spect_bin, $
                                            spect_band_signal=emission_wavelength_range, $
                                            spect_band_bg=background_wavelength_range)
  print, 'Absolute Intensity (BG Subtracted): '+strcompress(string(intensity),/remove_all)+' Rayleighs'
  
  ; Once again, we can also perform this calculation for a time series of spectrograph data. Let's
  ; use the same time range as before (the entire hour)
  intensity = aurorax_spectra_get_intensity(spect_data, ts_arr, spect_bin, $
                                            spect_band_signal=emission_wavelength_range, $
                                            spect_band_bg=background_wavelength_range)
  
  ; Plot the manually selected emission intensities as a function of time
  p_manual = plot(julian_ts_arr, intensity, xtickunits='Time', xtickformat='(C(CHI2.2,":",CMI2.2))', color='black', $
                  thick=2, xtitle='Time (UTC)', ytitle='Intensity (Rayleighs)', title='TREx-Spectrograph bin 150 (Manually Selected Emission)', $
                  dimensions=[800,300], location=[820,150], yrange=[0,3000])
end
