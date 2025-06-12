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

pro aurorax_example_movie_mosaic_trex_rgb
  ; ------------------------------
  ; Creating TREx RGB Mosaic Movie
  ; ------------------------------
  ;
  ; Using PyAuroraX's built-in movie function in combination with the
  ; mosaic tools, we can generate a mosaic movie.
  ;
  ; Let's have a look at an example of making a movie for 1 minute of
  ; TREx RGB data projected onto a map. This process can be extended
  ; to larger time ranges easily, but generating the mosaic frames
  ; takes a while, so for this example we will limit it to 1 minute
  ; of data (20 frames).
  ;
  
  ; Initialize list to hold image data and skymaps
  image_list = list()
  skymap_list = list()

  ; Date of Interest
  start_dt = '2023-02-24T06:15:00'
  end_dt = '2023-02-24T06:15:00'
  
  ; Iterate through sites we want to included in the mosaic
  foreach site, ['yknf', 'gill', 'rabb'] do begin
    ; download and read image data for this site and add to list
    d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', start_dt, end_dt, site_uid = site)
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    image_list.add, image_data

    ; download and read the correct skymap for this site and add to list
    d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', site, start_dt)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap = skymap_data.data[0]
    skymap_list.add, skymap
  endforeach

  ; Prepare image data and skymaps for mosaic plotting
  altitude_km = 110
  prepped_images = aurorax_mosaic_prep_images(image_list)
  prepped_skymaps = aurorax_mosaic_prep_skymap(skymap_list, altitude_km)

  ; Now, we need to create a direct graphics map that the data can be plotted
  ; onto. Using, the map_set procedure (see IDL docs for info), create the map
  ; however you'd like. Below is an example
  land_color = aurorax_get_decomposed_color([186, 186, 186])
  water_color = aurorax_get_decomposed_color([64, 89, 120])
  border_color = aurorax_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = aurorax_get_decomposed_color([0, 0, 0])

  ; set up map projection
  map_bounds = [40, 220, 80, 290]
  ilon = 255
  ilat = 56

  ; Define scaling bounds for image data - in this case we just use an array to scale all sites
  ; the same - alternatively, one can use a hash to scale images on a per-site basis
  scale = [10, 105]
  
  ; --------------------------------
  ; Creating the mosaic movie frames 
  ;
  ; Now that everything is set up, we need to plot the mosaic for each timestamp,
  ; and save it as an image. Then, we can pass those image files into the
  ; aurorax_movie procedure.
  ;
  
  ; Set up your writing directory
  ;
  ; NOTE: We will use the user's home directory for it here. Change as needed.
  home_dir = getenv('USERPROFILE') ; Windows
  if (home_dir eq '') then home_dir = getenv('HOME') ; Unix/Linux/macOS
  working_dir = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_mosaic_movie_frames_example'
  if not file_test(working_dir) then file_mkdir, working_dir

  ; Let's make one frame for each timestmap in the data we've prepared
  mosaic_ts_list = prepped_images['timestamps']
  foreach ts, mosaic_ts_list, i do begin
    
    print, 'Processing frame '+strcompress(string(i+1),/remove_all)+'/'+strcompress(string(n_elements(mosaic_ts_list)),/remove_all)
    
    ; Format this iterations timestamp to expected input for `aurorax_mosaic_plot` procedure
    mosaic_dt = strjoin(strsplit(ts, ' ', /extract), 'T')
    
    ; plot the empty map in a window
    window, 0, xsize = 800, ysize = 600, xpos = 0
    map_win_loc = [0., 0., 1., 1.]
    device, decomposed = 1
    polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
    polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
    map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
    map_continents, /fill, /countries, color = land_color
    map_continents, color = border_color, mlinethick = border_thick

    ; Plot some gridlines
    gridline_color = aurorax_get_decomposed_color([0, 0, 0])
    clats = [30, 40, 50, 60, 70, 80]
    clons = [200, 220, 240, 260, 280, 300, 320, 340]
    aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2

    ; The aurorax_mosaic_oplot routine also includes a /mag option, to overplot contours
    ; that are defined in geomagnetic (AACGM) coordinates
    magnetic_gridline_color = aurorax_get_decomposed_color([255, 179, 0])
    clats = [63, 77]
    aurorax_mosaic_oplot, constant_lats = clats, color = magnetic_gridline_color, linestyle = 0, thick = 6, /mag
    
    ; Call the mosaic creation function to plot the mosaic in the current window
    aurorax_mosaic_plot, prepped_images, prepped_skymaps, mosaic_dt, intensity_scales = scale
    
    ; Overplot some text
    !p.font = 1
    device, set_font = 'Helvetica Bold', /tt_font, set_character_size = [7, 7]
    xyouts, 0.01, 0.9, 'TREx RGB', /normal, font = 1, charsize = 6
    xyouts, 0.01, 0.01, ts + ' UTC', /normal, font = 1, charsize = 5
    !p.font = -1
    
    ; Save the frame
    frame_fname = working_dir + path_sep() + 'frame' + string(i, format = '(I3.3)') + '.png'
    write_png, frame_fname, tvrd(/true)
  endforeach
  
  ; Set the input and output filenames
  filenames = file_search(working_dir + path_sep() + '*')
  output_filename = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_mosaic_example_movie.mp4'

  ; Now call the movie procedure by passing in the list of filenames
  movie_fps = 5
  aurorax_movie, filenames, output_filename, movie_fps

end