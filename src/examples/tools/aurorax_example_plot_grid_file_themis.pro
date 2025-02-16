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

pro aurorax_example_plot_grid_file_themis
  compile_opt idl2

  ; First, download and read 5 minutes of grid data
  d = aurorax_ucalgary_download('THEMIS_ASI_GRID_MOSV001', '2023-03-24T08:10:00', '2023-03-24T08:10:00')
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
  rgba_grid = aurorax_prep_grid_image(grid, fill_val, scale = [0, 12500])

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
  t = text(0.235, 0.875, 'THEMIS ASI - Gridded Data', font_size = 20, color = 'white', font_style = 1)
  t = text(0.235, 0.165, '2023/03/24', font_size = 20, color = 'white', font_style = 1)
  t = text(0.235, 0.105, '08:10:00 UT', font_size = 20, color = 'white', font_style = 1)
end
