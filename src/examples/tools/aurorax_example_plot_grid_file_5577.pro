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

pro aurorax_example_plot_grid_file_5577
  ; ------------------------------------
  ; Plot TREx RGB 5577-Derived Grid Data
  ; ------------------------------------
  ;
  ; We are developing new array-wide standard grid data products for our data. We refer
  ; to these as 'grid files', since they are data organized into a common grid format:
  ;
  ; 512 x 1024 latitude by longitude (~0.3 degrees per bin).
  ;
  ; For the optical instruments, the grid files are a downsampled pre-computed mosaic.
  ; Preventing the need to download the raw data and generate your own mosaic which can
  ; be tedious and compute/network intensive. Of course, if these grid files are not
  ; good enough, you can always still download the raw data and generate your own mosaic
  ; as you'd like for full control.
  ;
  ; Let's have a look at downloading and plotting a grid file for the TREx RGB
  ; 5577-derived dataset. These grid files provide the 557.7 nm greenline emission in
  ; each grid cell, as derived according to the procedure prescribed by:
  ; Liang et al. (2024) (http://dx.doi.org/10.26464/epp2023063)
  ;

  ; First, download and read 5 minutes of grid data
  d = aurorax_ucalgary_download('TREX_RGB5577_GRID_MOSV001', '2023-03-24T07:30:00', '2023-03-24T07:40:00')
  grid_data = aurorax_ucalgary_read(d.dataset, d.filenames, start_dt = '2023-03-24T07:35:00', end_dt = '2023-03-24T07:35:00', /first_record)

  ; Grab the first frame and corresponding_timestamp
  grid = grid_data.data.grid
  timestamp = grid_data.metadata.timestamp

  ; The fill value used for cells with no data is stored in the metadata
  fill_val = float(grid_data.metadata.file_meta.fill_value)

  ; To plot the grid on top of a map, we need to make all cells that contain no data
  ; transparent. To do so, we simply conver the image array to an RGBA image, and set all
  ; values where the array equals the fill value, to the maximum transparency. This is
  ; easily achieved via the aurorax_prep_grid_image() function.
  rayleighs_scale = [0, 25000]
  rgba_grid = aurorax_prep_grid_image(grid, fill_val, scale = rayleighs_scale, color_table = 8)

  ; Create a map
  map_limit = [41, -140, 75, -70]
  ortho_map = map('orthographic', limit = map_limit, linestyle = '', label_show = 0, fill_color = 'black', dimensions = [1024, 512], $
    center_latitude = 60, center_longitude = -90)
  cont1 = mapcontinents(fill_color = 'dark slate gray')
  cont2 = mapcontinents(/canada, fill_color = 'dark slate gray')
  cont3 = mapcontinents(/lakes, fill_color = 'black')

  ; Plot the RGBA grid data, with transparency, on the map
  gridimg = image(rgba_grid, limit = [0, -180, 90, 0], grid_units = 2, image_location = [-180, -90], image_dimensions = [360, 180], center_latitude = 60, center_longitude = -90, $
    map_projection = 'orthographic', background_color = 'black', /overplot)

  ; Add some labels and a custom colorbar
  t = text(0.235, 0.875, 'TREx RGB - Derived 557.7 nm', font_size = 20, color = 'white', font_style = 1)
  t = text(0.235, 0.165, strmid(timestamp, 0, 10), font_size = 20, color = 'white', font_style = 1)
  t = text(0.235, 0.105, strmid(timestamp, 11, 12), font_size = 20, color = 'white', font_style = 1)
  cbar = colorbar(range = rayleighs_scale, orientation = 1, position = [0.7, 0.1, 0.71, 0.9], textpos = 1, tickdir = 1, font_style = 1, font_size = 10, $
    border_on = 1, color = 'white', rgb_table = 8, tickname = ['0 kR', '5 kR', '10 kR', '15 kR', '20 kR', '25+ kR'])
end
