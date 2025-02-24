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

;+
; :Description:
;       Plot a keogram object.
;
;       Defaults to CCD axis (use geo, mag, elev, to change this).
;
; :Parameters:
;       keogram_struct: in, required, Object
;         keogram object to plot, usually the return value of aurorax_keogram_create()
;
; :Keywords:
;       title: in, optional, String
;         string giving the plot title
;       dimensions: in, optional, Array
;         two-element array giving dimensions of the plotting window in device coordinates
;       location: in, optional, Array
;         two-element array giving location of the plotting window in device coordinates
;       x_tick_interval: in, optional, Integer
;         interval between ticks on the x-axis (default is 200)
;       y_tick_interval: in, optional, Integer
;         interval between ticks on the y-axis (default is 50)
;       aspect_ratio: in, optional, Float
;         float giving the aspect ratio to display keogram data
;       colortable: in, optional, Integer
;         int giving the IDL colortable to use for the keogram
;       geo: in, optional, Boolean
;         labels geographic coordinates on the y-axis (axis must exist in keogram structure)
;       mag: in, optional, Boolean
;         labels geomagnetic coordinates on the y-axis (axis must exist in keogram structure)
;       elev: in, optional, Boolean
;         labels elevation angles on the y-axis (axis must exist in keogram structure)
;
; :Examples:
;       aurorax_keogram_plot, keo, title="Geographic", /geo, location=[0,0], dimensions=[1000,400]
;+
pro aurorax_keogram_plot, $
  keogram_struct, $
  geo = geo, $
  mag = mag, $
  elev = elev, $
  dimensions = dimensions, $
  location = location, $
  title = title, $
  x_tick_interval = x_tick_interval, $
  y_tick_interval = y_tick_interval, $
  aspect_ratio = aspect_ratio, $
  colortable = colortable
  axis_keywords = [keyword_set(geo), keyword_set(mag), keyword_set(elev)]
  if total(axis_keywords) gt 1 then begin
    print, '[aurorax_keogram_plot] Error: Only one of ''/geo'', ''/mag'', ''/elev'' may be set'
    goto, error_jump
  endif

  ; Make sure desired axis exists
  if keyword_set(geo) and where('GEO_Y' eq tag_names(keogram_struct), /null) eq !null then begin
    print, '[aurorax_keogram_plot] Error: Keyword ''/geo'' was set, but input keogram has no geographic axis. Use aurorax_keogram_add_axis().'
    goto, error_jump
  endif
  if keyword_set(mag) and where('MAG_Y' eq tag_names(keogram_struct), /null) eq !null then begin
    print, '[aurorax_keogram_plot] Error: Keyword ''/mag'' was set, but input keogram has no magnetic axis. Use aurorax_keogram_add_axis().'
    goto, error_jump
  endif
  if keyword_set(elev) and where('ELEV_Y' eq tag_names(keogram_struct), /null) eq !null then begin
    print, '[aurorax_keogram_plot] Error: Keyword ''/elev'' was set, but input keogram has no elevation axis. Use aurorax_keogram_add_axis().'
    goto, error_jump
  endif

  ; Select desired axis
  if keyword_set(geo) then begin
    y = keogram_struct.geo_y
  endif else if keyword_set(mag) then begin
    y = keogram_struct.mag_y
  endif else if keyword_set(elev) then begin
    y = keogram_struct.elev_y
  endif else begin
    y = keogram_struct.ccd_y
  endelse

  ; Extract keogram data
  keo_arr = bytscl(keogram_struct.data)

  ; Get number of channels
  if n_elements(size(keo_arr, /dimensions)) eq 3 then begin
    n_channels = (size(keo_arr, /dimensions))[0]
  endif else begin
    n_channels = 1
  endelse

  if keyword_set(aspect_ratio) then aspect = aspect_ratio else aspect = 1

  ; Get dimensions of keogram
  if n_channels eq 1 then begin
    keo_width = (size(keo_arr, /dimensions))[0]
    keo_height = (size(keo_arr, /dimensions))[1]
  endif else begin
    keo_width = (size(keo_arr, /dimensions))[1]
    keo_height = (size(keo_arr, /dimensions))[2]
  endelse

  if not keyword_set(dimensions) then dimensions = [keo_width + 100, keo_height + 100]
  if not keyword_set(location) then dimensions = [0, 0]
  if not isa(x_tick_interval) then x_tick_interval = 200
  if not isa(y_tick_interval) then y_tick_interval = 50

  ; Create the plot
  w = window(dimensions = dimensions, location = location)

  if not keyword_set(colortable) then colortable = 0
  keo_image = image(keo_arr, /current, axis_style = 4, aspect_ratio = aspect, rgb_table = colortable)
  if keyword_set(title) and isa(title, /string) then keo_image.title = title

  ; Create the x axis (time)
  timestamp_axis = []
  for i = 0, n_elements(keogram_struct.timestamp) - 1, x_tick_interval do begin
    timestamp_axis = [timestamp_axis, strmid(keogram_struct.timestamp[i], 11, 5)]
  endfor
  timestamp_axis = [timestamp_axis, strmid(keogram_struct.timestamp[-1], 11, 5)]
  x_axis = axis('X', location = 0)
  x_axis.tickinterval = x_tick_interval
  x_axis.tickname = timestamp_axis
  x_axis.title = 'Time (UTC)'
  x_axis.text_orientation = 0

  ; For custom keogram, don't plot a y-axis because we can't create a well defined y-axis
  if isa(y, /string, /scalar) then goto, custom_keogram_jump

  ; Create desired y-axis
  coord_axis = []
  for i = 0, n_elements(y) - 1, y_tick_interval do begin
    if ~finite(y[i]) or i eq 0 or y[i] lt 0 then begin
      coord_axis = [coord_axis, '']
    endif else begin
      coord_axis = [coord_axis, strmid(strcompress(string(y[i]), /remove_all), 0, 4)]
    endelse
  endfor
  if keogram_struct.axis eq 0 then begin
    y_title = (['Geographic Latitude', 'Magnetic Latitude', 'Elevation', 'CCD Y'])[where(axis_keywords)]
  endif else begin
    y_title = (['Geographic Longitude', 'Magnetic Longitude', 'Elevation', 'CCD Y'])[where(axis_keywords)]
  endelse
  y_axis = axis('Y', location = 0)
  y_axis.tickinterval = y_tick_interval
  y_axis.tickname = coord_axis
  y_axis.title = y_title

  custom_keogram_jump:
  error_jump:
end
