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

pro aurorax_example_plot_grid_file_6300
  ; -------------------
  ; Plot REGO Grid Data
  ; -------------------
  ;
  ; We are developing new array-wide standard grid data products for our data.
  ; We refer to these as 'grid files', since they are data organized into a common
  ; grid format:
  ; 
  ;   512 x 1024 latitude by longitude (~0.3 degrees per bin).
  ; 
  ; For the optical instruments, the grid files are a downsampled pre-computed mosaic.
  ; Preventing the need to download the raw data and generate your own mosaic which can
  ; be tedious and compute/network intensive. Of course, if these grid files are not
  ; good enough, you can always still download the raw data and generate your own mosaic
  ; as you'd like for full control.
  ; 
  ; Let's have a look at downloading and plotting a grid file for the REGO dataset.
  ; 
  ; Note that these grid files are created usng the common calibration procedure for
  ; REGO and thus each grid cell gives the 630.0 nm redline emission intensity.
  ;

  ; First, download and read 5 minutes of grid data
  d = aurorax_ucalgary_download('REGO_GRID_MOSV001', '2023-03-24T04:45:00', '2023-03-24T04:45:00')
  grid_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Grab the first frame and corresponding_timestamp
  grid = grid_data.data.grid[*, *, 0]
  timestamp = grid_data.metadata.timestamp[0]

  ; The fill value used for cells with no data is stored in the metadata
  fill_val = float(grid_data.metadata.file_meta[0].fill_value)

  ; To plot the grid on top of a map, we need to make all cells that contain no data
  ; transparent. To do so, we simply conver the image array to an RGBA image, and set all
  ; values where the array equals the fill value, to the maximum transparency. This is
  ; easily achieved via the aurorax_prep_grid_image() function.
  rayleighs_scale = [0, 5000]
  rgba_grid = aurorax_prep_grid_image(grid, fill_val, scale = rayleighs_scale, color_table = 3)

  ; Create a map
  map_limit = [41, -140, 78, -60]
  ortho_map = map('orthographic', limit = map_limit, linestyle = '', label_show = 0, fill_color = 'black', dimensions = [1024, 512], $
    center_latitude = 60, center_longitude = -90)
  cont1 = mapcontinents(fill_color = 'dark slate gray')
  cont2 = mapcontinents(/canada, fill_color = 'dark slate gray')
  cont3 = mapcontinents(/lakes, fill_color = 'black')

  ; Plot the RGBA grid data, with transparency, on the map
  gridimg = image(rgba_grid, limit = [0, -180, 90, 0], grid_units = 2, image_location = [-180, -90], image_dimensions = [360, 180], center_latitude = 60, center_longitude = -90, $
    map_projection = 'orthographic', background_color = 'black', /overplot)

  ; Add some labels
  t = text(0.235, 0.875, 'REGO - Calibrated 630.0 nm', font_size = 20, color = 'white', font_style = 1)
  t = text(0.235, 0.165, '2023/03/24', font_size = 20, color = 'white', font_style = 1)
  t = text(0.235, 0.105, '04:45:00 UT', font_size = 20, color = 'white', font_style = 1)
  cbar = colorbar(range = rayleighs_scale, orientation = 1, position = [0.73, 0.1, 0.74, 0.9], textpos = 1, tickdir = 1, font_style = 1, font_size = 10, $
    border_on = 1, color = 'white', rgb_table = 3, tickname = ['0 kR', '1 kR', '2 kR', '3 kR', '4 kR', '5+ kR'])
end
