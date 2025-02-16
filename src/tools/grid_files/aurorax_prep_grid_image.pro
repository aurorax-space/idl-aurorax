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

; -------------------------------------------------------------
;+
; NAME:
;       AURORAX_PREP_GRID_IMAGE
;
; PURPOSE:
;       Prepare a grid file array to be plotted.
;
; EXPLANATION:
;       Takes a grid array, and converts it to RGBA format, masking
;       all empty cells with max transparency, so that it can be plotted
;       overtop of a map.
;
; CALLING SEQUENCE:
;       aurorax_prep_grid_image(grid, fill_val, scale=[s_min, s_max], color_table=3)
;
; PARAMETERS:
;       grid            The grid array to prepare. Usually a result of reading a grid file
;                       and obtaining grid data from said file.
;       fill_val        The fill value that was used to fill grid cells containing no data.
;                       Usually obtained from the grid file's metadata.
;       scale           A two-element array specifying the minimum and maximum values to
;                       scale data between, optional (defaults to data min/max).
;       color_table     An integer specifying the IDL rgb colortable to use for preparing
;                       single-channel data, optional (defaults to 0, gray).
;
; KEYWORDS:
;
; OUTPUT
;       the prepared RGBA grid
;
; OUTPUT TYPE:
;       array
;
; EXAMPLES:
;       rgba_grid = aurorax_prep_grid_image(grid, -999.0, scale=[0, 5000], color_table=3)
;+
;-------------------------------------------------------------
function aurorax_prep_grid_image, grid, fill_value, color_table = color_table, scale = scale
  compile_opt idl2

  if not isa(color_table) then color_table = 0

  if n_elements(size(grid, /dimensions)) eq 2 then begin
    n_channels = 1
  endif else if n_elements(size(grid, /dimensions)) eq 3 and (size(grid, /dimensions))[0] eq 3 then begin
    n_channels = 3
  endif else begin
    print, '[aurorax_prep_grid_image] Error: currently, function is only compatible with single images of ' + $
      'size [cols, rows] or [channels, cols, rows].'
    return, !null
  endelse

  grid_dims = size(grid, /dimensions)

  if n_channels eq 1 then begin
    grid_w = grid_dims[0]
    grid_h = grid_dims[1]
    customct = colortable(color_table)
    masked_rgba_array = bytarr(4, n_elements(grid))
  endif else if n_channels eq 3 then begin
    grid_w = grid_dims[1]
    grid_h = grid_dims[2]
    customct = colortable(color_table)
    masked_rgba_array = bytarr(4, n_elements(grid[0, *, *]))
  endif

  byte_grid = grid
  byte_grid[where(byte_grid eq fill_value)] = 0
  if not keyword_set(scale) then begin
    byte_grid = bytscl(grid)
  endif else begin
    byte_grid = bytscl(grid, min = scale[0], max = scale[1])
  endelse

  if n_channels eq 1 then begin
    masked_rgba_array[0, where(grid ne fill_value)] = customct[byte_grid[where(grid ne fill_value)], 0]
    masked_rgba_array[1, where(grid ne fill_value)] = customct[byte_grid[where(grid ne fill_value)], 1]
    masked_rgba_array[2, where(grid ne fill_value)] = customct[byte_grid[where(grid ne fill_value)], 2]
    masked_rgba_array[3, where(grid ne fill_value)] = 255
  endif else begin
    masked_rgba_array[0 : 2, *] = byte_grid
    masked_rgba_array[3, where(grid[0, *, *] eq fill_value and grid[1, *, *] eq fill_value and grid[2, *, *] eq fill_value)] = 0
    masked_rgba_array[3, where(~(grid[0, *, *] eq fill_value and grid[1, *, *] eq fill_value and grid[2, *, *] eq fill_value))] = 255
  endelse

  masked_rgba_array = reform(masked_rgba_array, 4, grid_w, grid_h)
  return, masked_rgba_array
end
