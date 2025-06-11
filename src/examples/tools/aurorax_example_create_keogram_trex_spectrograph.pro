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

pro aurorax_example_create_keogram_trex_spectrograph
  ; ---------------------------------
  ; Creating a TREx Specrograph keogram
  ; ---------------------------------
  ;
  ; Like with ASI data, keograms can be a helpful data product for summarizing spectrograph
  ; data over some time period. In the case of a meridian scanning spectrograph like TREx
  ; Spectrograph, the meridional slices of data measured by the spectrograph can be stacked
  ; in time. Given that the spectrographs measure a range of wavelengths (~ 400-800 nm in the
  ; case of TREx), the spectra must be integrated to create spectrograph keograms of select
  ; emissions. Because of this, the aurorax_keogram_create() function has built in options
  ; for handling spectrograph data.
  ;
  ; Below, we'll work through the creation of a 5 minute keogram created from TREx Spectrograph 
  ; L1 processed data.
  ;
  
  ; First, read one hour of processed (L1) spectrograph data
  d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', '2021-02-16T09:00', '2021-02-16T09:59', site_uid = 'rabb')
  spect_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; To create a keogram for spectrograph data, we need to pull out the spectral data, the timestamps, and the wavelengths
  spectra =  spect_data.data.spectra
  timestamps = spect_data.timestamp
  wavelengths= spect_data.metadata.wavelength
  
  ; Call the keogram create function, with some additional arguments. The /spectra keyword
  ; tells the function that specrograph data is being passed in, which also requires a 
  ; wavelength array to be supplied
  keogram = aurorax_keogram_create(spectra, timestamps, /spectra, wavelength=wavelengths)
  
  ; Like any other keogram, f you wanted to further manipulate or manually plot the keogram
  ; array, you can grab it like this:
  keo_arr = keogram.data
  
  ; Plot with aurorax function
  p = aurorax_keogram_plot(keogram, location = [0, 0], title = 'TREx Spectrograph Keogram - 557.7 nm', $
                           dimensions = [1000, 400], aspect_ratio=0.35, x_tick_interval=40, colortable=8)
                           
  ; For the above keogram, we did not specify which emission to pull from the spectrograph data
  ; in creating the keogram, and so the default 557.7 nm greenline emission was used.
  
  ; You might want to make several keograms of the different available spect_emission keyword options
  ; which allow you to automatically create keograms for the HBeta, blueline, greenline, and redline emissions
  
  ; First, create a keogram of each emission
  keo_hbeta = aurorax_keogram_create(spectra, timestamps, /spectra, wavelength=wavelengths, spect_emission='hbeta')
  keo_blue = aurorax_keogram_create(spectra, timestamps, /spectra, wavelength=wavelengths, spect_emission='blue')
  keo_green = aurorax_keogram_create(spectra, timestamps, /spectra, wavelength=wavelengths, spect_emission='green')
  keo_red = aurorax_keogram_create(spectra, timestamps, /spectra, wavelength=wavelengths, spect_emission='red')
  
  ; Plot each keogram... You may want to add a colorbar, since these keograms are in units of Rayleighs
  p_hbeta = aurorax_keogram_plot(keo_hbeta, location = [0, 200], title = '486.1 nm', $
                           dimensions = [800, 400], aspect_ratio=0.35, x_tick_interval=40, colortable=0)
  legend_tickval_str = strcompress(string(ulong(findgen(6, start=0, increment=max(keo_hbeta.data)/5.0))),/remove_all)
  legend_hbeta = colorbar(target=p_hbeta, title='Intensity (Rayleighs)', position=[0.6,0.9,0.9,0.95], tickname=legend_tickval_str)
  
  p_blue = aurorax_keogram_plot(keo_blue, location = [850, 200], title = '427.8 nm', $
                           dimensions = [800, 400], aspect_ratio=0.35, x_tick_interval=40, colortable=1)
  legend_tickval_str = strcompress(string(ulong(findgen(6, start=0, increment=max(keo_blue.data)/5.0))),/remove_all)
  legend_blue = colorbar(target=p_blue, title='Intensity (Rayleighs)', position=[0.6,0.9,0.9,0.95], tickname=legend_tickval_str)
                           
  p_green = aurorax_keogram_plot(keo_green, location = [0, 1000], title = '557.7 nm', $
                           dimensions = [800, 400], aspect_ratio=0.35, x_tick_interval=40, colortable=8)
  legend_tickval_str = strcompress(string(ulong(findgen(6, start=0, increment=max(keo_green.data)/5.0))),/remove_all)
  legend_green = colorbar(target=p_green, title='Intensity (Rayleighs)', position=[0.6,0.9,0.9,0.95], tickname=legend_tickval_str)
                           
  p_red = aurorax_keogram_plot(keo_red, location = [850, 1000], title = '630.0 nm', $
                           dimensions = [800, 400], aspect_ratio=0.35, x_tick_interval=40, colortable=3)
  legend_tickval_str = strcompress(string(ulong(findgen(6, start=0, increment=max(keo_red.data)/5.0))),/remove_all)
  legend_red = colorbar(target=p_red, title='Intensity (Rayleighs)', position=[0.6,0.9,0.9,0.95], tickname=legend_tickval_str)

  ;------------------------------------
  ; Reference in geographic coordinates
  ;
  ; For each camera, the UCalgary maintains a geospatial calibration dataset that maps pixel
  ; coordinates (detector X and Y) to local observer and geodetic coordinates (at altitudes
  ; of interest). We refer to this calibration as a 'skymap'. The skymaps may change due to
  ; the freeze-thaw cycle and changes in the building, or when the instrument is serviced.
  ; A skymap is valid for a range of dates. The metadata contained in a file includes the
  ; start and end dates of the period of its validity.
  ;
  ; Be sure you choose the correct skymap for your data timeframe. The aurorax_download_best_skymap()
  ; function is there to help you, but for maximum flexibility you can download a range of skymap
  ; files and use whichever you prefer. For a complete breakdown of how to choose the correct
  ; skymap for the data you are working with, refer to the crib sheet:
  ;
  ;     aurorax_example_skymaps.pro
  ;
  ; All skymaps can be viewed by looking at the data tree for
  ; the imager you are using (see https://data.phys.ucalgary.ca/). If you believe the geospatial
  ; calibration may be incorrect, please contact the UCalgary team.
  ;
  ; For more on the skymap files, please see the skymap file description document:
  ;   https://data.phys.ucalgary.ca/sort_by_project/other/documentation/skymap_file_description.pdf
  ;
  
  ; Download and read the corresponding skymap
  d = aurorax_ucalgary_download_best_skymap('TREX_SPECT_SKYMAP_IDLSAV', 'rabb', '2021-02-16T09:00')
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  skymap = skymap_data.data[0]
  
  ; Add geographic, elevation, and geomagnetic axes to the keogram object                           Plot using magnetic coord axis
  keo_red = aurorax_keogram_add_axis(keo_red, skymap, /geo, /elev, /mag, altitude_km = 110)   ;         \/ 
  p_red = aurorax_keogram_plot(keo_red, location = [900, 0], title = '630.0 nm - AACGM Coordinates)', /mag, $
                               dimensions = [1000, 500], aspect_ratio=0.35, x_tick_interval=40, colortable=3)
  
  ; -------------------------
  ; Dealing with missing data
  ;
  ; When a keogram is created with aurorax_keogram_create() it will, by default, only include timetamps
  ; for which data exists. You may want to indicate missing data in the keogram, and this can be easily
  ; achieved using the aurorax_keogram_inject_nans() function.
  ;
  ; As an example, the below code creates a keogram for a different date with some missing data, and
  ; then calls the aurorax_keogram_inject_nans() function before plotting.

  ; Download and read some more TREx Spectrograph data
  d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', '2023-03-17T04:00:00', '2023-03-17T04:59:00', site_uid = 'rabb')
  spect_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  spectra = spect_data.data.spectra
  timestamps = spect_data.timestamp
  wavelengths = spect_data.metadata.wavelength
  
  ; Create keogram object
  keo = aurorax_keogram_create(spectra, timestamps, /spectra, wavelength=wavelengths, spect_emission='green')
  original_shape = size(keo.data, /dimensions)

  ; Now call the aurorax_keogram_inject_nans()
  ;
  ; Note that by default, this function will determine the cadence of the image
  ; data automatically to determine where the missing data is, but a cadence keyword
  ; is also available to manually supply a cadence
  keo = aurorax_keogram_inject_nans(keo)
  new_shape = size(keo.data, /dimensions)

  ; Plot the keogram with missing data indicated as you normally would
  p3 = aurorax_keogram_plot(keo, title = 'Spectrograph (557.7 nm) Keogram with Missing Data', location = [850, 0], dimensions = [1000, 400], $
                            aspect_ratio=0.35, x_tick_interval=40, colortable=8)

  ; Inspecting the shape reveals that indeed there was missing data, which
  ; has been filled using the aurorax_keogram_inject_nans() function
  print
  print, "Original Keogram Shape:"
  print, original_shape
  print
  print, "Keogram Shape after aurorax_keogram_inject_nans():"
  print, new_shape
end