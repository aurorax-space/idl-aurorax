;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

pro aurorax_example_plot_grid_file_rgb

  ; First, download and read 5 minutes of grid data
  d = aurorax_ucalgary_download('TREX_RGB_GRID_MOSV001', '2023-03-24T08:10:00', '2023-03-24T08:10:00')
  grid_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; Grab the first frame and corresponding_timestamp
  grid = grid_data.data.grid[*,*,*,0]
  timestamp = grid_data.metadata.timestamp[0]
  
  fill_val = -999.0
  ; To plot the grid on top of a map, we need to make all cells that contain no data
  ; transparent. To do so, we simply add an alpha channel to the array, and set all
  ; values where the array equals the fill value, to the maximum transparency
  transparent_grid = bytarr((size(grid, /dimensions))[0]+1, (size(grid, /dimensions))[1], (size(grid, /dimensions))[2])
  is_data_idx = where(reform(grid[0,*,*]) ne -999)
  grid[where(grid eq fill_val)] = 0
  flat_alpha_channel = reform(transparent_grid[3,*,*], (size(grid, /dimensions))[1]*(size(grid, /dimensions))[2])
  flat_alpha_channel[is_data_idx] = 255
  alpha_channel = reform(flat_alpha_channel, (size(grid, /dimensions))[1], (size(grid, /dimensions))[2])
  transparent_grid[3,*,*] = alpha_channel
  transparent_grid[0:2,*,*] = bytscl(grid)
  
  ; Create a map
  map_limit = [41,-140,75,-70]
  ortho_map = map('orthographic', limit=map_limit, linestyle='', label_show=0, fill_color='black', dimensions=[1024,512], $
    center_latitude=60, center_longitude=-90)
  cont1 = mapcontinents(fill_color='dark slate gray')
  cont2 = mapcontinents(/canada, fill_color='dark slate gray')
  cont3 = mapcontinents(/lakes, fill_color = 'black')
  
  ; Plot the grid data, with transparency, on the map
  gridimg = image(transparent_grid, LIMIT=[0,-180,90,0], GRID_UNITS=2, IMAGE_LOCATION=[-180,-90], IMAGE_DIMENSIONS=[360,180], center_latitude=60, center_longitude=-90, $
                  MAP_PROJECTION='orthographic', BACKGROUND_COLOR='black', /overplot)
  
  ; Add some labels
  t = text(0.235, 0.875, 'TREx RGB - Gridded Data', font_size=20, color='white', font_style=1)
  t = text(0.235, 0.165, '2023/03/24', font_size=20, color='white', font_style=1)
  t = text(0.235, 0.105, '08:10:00 UT', font_size=20, color='white', font_style=1)
end







