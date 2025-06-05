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

pro aurorax_example_plot_spectrograph_data
  ; ---------------------------
  ; Plot TREx Spectrograph Data
  ; ---------------------------
  ; 
  ; Note:
  ;   TREx Spectrograph L1 data is organized into 1-hour files, whereas the ASI data
  ;   is 1-minute files. This means that files are a bit bigger when downloading them,
  ;   and for RAM-limited systems you have to be a bit more mindful when reading data.
  ;   To help, the `aurorax_ugalgary_read()` function has a `start_time` and `end_time`
  ;   parameter to allow you to only read in a certain timeframe of data (ie. just 10
  ;   minutes). We won't be utilizing this below, but be aware that it is available.
  ;   
  ; When working with the TREx Spectrograph data, it can be valuable to plot a timeseries
  ; for various wavelengths. 
  ; 
  ; This crib sheet walks through several examples of doing so, for some common auroral
  ; emissions, as well as using a manually defined emission (range of wavlengths to 
  ; integrate spectral data over).
  ; 
  
  ; First, read one hour of processed (L1) spectrograph data
  d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', '2021-02-16T09:00', '2021-02-16T09:59', site_uid = 'rabb')
  spect_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; ---------------
  ; Simple Plotting
  ; 
  ; For an hour of spectrograph data, we will have a number of spectra, taken from different times (every 15 seconds
  ; for TREx-Spectrograph).
  ; 
  ; Also, since these are meridian-scanning spectrographs, we will have a number of spectrographs that correspond to
  ; different points in the sky (spatial bins), along the scan, for each timestamp.
  ;
  
  ; Let's plot a single spectrum, from one time within our hour of data at one location (spectrograph bin,
  ; i.e> spect_loc, 0-255 for TREx)
  t_0 = '2021-02-16T09:30:00'
  spect_bin = 150
  
  ; Create the plot object
  p = aurorax_spectra_plot(spect_data, t_0, spect_bin, color='blue')
  
  ; --------------------------------------
  ; Plotting spectra of Multiple Locations
  ; 
  ; Let's compare the spectra of two different locations, at the same time
  ;
  t_0 = '2021-02-16T09:30:00'
  spect_bin = [190, 80]
  colors = ['blue', 'red']
  p = aurorax_spectra_plot(spect_data, t_0, spect_bin, color=colors, ylim=[0,10000], location=[850,0], title = 'Spectra of two locations')
  
  ; ----------------------------------------
  ; Plotting Spectra of a Location Over Time
  ; 
  ; You might want to look at how the spectrum at a particular location evolves over time:
  ;
  t_0 = '2021-02-16T09:30:00'
  t_1 = '2021-02-16T09:40:00'
  t_2 = '2021-02-16T09:50:00'
  spect_bin = 90
  colors = ['blue', 'red', 'green']
  p = aurorax_spectra_plot(spect_data, [t_0, t_1, t_2], spect_bin, color=colors, ylim=[0,10000], location=[0,500], title = "Spectrum over time")
  
  ; --------------------------------
  ; Zooming in and Marking Emissions
  ; 
  ; Maybe you are only interested in the 557.7 and 630.0 nm emissions. First of all
  ; you could restrict your plot to this region
  ;
  xlim = [520, 660]
  
  ; Again, looking at a single location, at two times
  t_0 = '2021-02-16T09:02:15'
  t_1 = '2021-02-16T09:10:00' 
  spect_bin = 41
  colors = ["dodger blue", "purple"]
  
  ; Call the plotting function, this time using a logarithmic y-axis, and adding the line emissions we want to indicate
  p = aurorax_spectra_plot(spect_data, [t_0, t_1], spect_bin, color=colors, ylim=[1,10000], location=[850,500], $
                           title = "TREx-Spectrograph (Rabbit Lake, Sk)", /ylog, /auto_legend)

  ; Note that the plot object can be manipulated after creation
  p.background_color = "cornsilk"
  
  ; You can also easily overplot the greenline and redline
  p = plot([557.7, 557.7], p.yrange, color='green', /current, /overplot, thick=2, linestyle=2)
  p = plot([630.0, 630.0], p.yrange, color='red', /current, /overplot, thick=2, linestyle=2)
end








