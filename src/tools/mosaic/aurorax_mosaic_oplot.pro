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
;       Plot lines of constant lat/lon, and custom points on a mosaic.
;
;       Plot either, or a combination of, lines of constant geographic or
;       geomagnetic latitude and/or longitude. Can also be used to plot
;       a single point in geographic or geomagnetic coordinates.
;
; :Keywords:
;       constant_lats: in, optional, Scalar or Array
;         a scalar or array giving latitude(s) to add constant lines
;       constant_lons: in, optional, Scalar or Array
;         a scalar or array giving longitude(s) to add constant lines
;       point: in, optional, Array
;         a two element array specifying the lon, lat to plot
;       color: in, optional, Long Integer
;         long integer giving the color to plot in (default is 0 i.e. black)
;       thick: in, optional, Integer
;         integer giving line thickness for any lines plotted (default is 1)
;       linestyle: in, optional, Integer
;         integer giving IDL linestyle (default is 0, i.e. solid)
;       symbol: in, optional, Integer
;         integer giving IDL symbol (default is 0, i.e. none for lines and circle for point)
;       symsize: in, optional, Integer
;         integer giving IDL symbol size (default is 1)
;       mag: in, optional, Boolean
;         specify that coordinates are given in geomagnetic coordinates (default is geographic)
;       aacgm_date: in, optioinal, String
;         a date string in the format 'YYYY-MM-DD' specifying the date to use for AACGM
;         coordinate transformations
;       aacgm_height: in, optional, String
;         input altitude (km) for geomagnetic (AACGM) coordinate transformations - if
;         not supplied, default is 0.0
;
; :Examples:
;       aurorax_mosaic_oplot, point=[245,61.2], color=aurorax_get_decomposed_color([0,0,255])
;       aurorax_mosaic_oplot, constant_lats=[40,50,60], constant_lons=[220,240,260], linestyle=2, thick=3
;+
pro aurorax_mosaic_oplot, $
  constant_lons = constant_lons, $
  constant_lats = constant_lats, $
  point = point, $
  color = color, $
  thick = thick, $
  linestyle = linestyle, $
  symbol = symbol, $
  symsize = symsize, $
  mag = mag, $
  aacgm_date = aacgm_date, $
  aacgm_height = aacgm_height
  device, get_decomposed = old_decomp
  device, decomposed = 1

  ; Set default values
  if not isa(color) then color = 0
  if not isa(thick) then thick = 1
  if not isa(linestyle) then linestyle = 0
  if not isa(symbol) then symbol = 0
  if not isa(symsize) then symsize = 1

  ; Make sure that all plot parameters are accepted
  if not isa(color, /scalar, /number) or color lt 0 or color gt aurorax_get_decomposed_color([255, 255, 255]) then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''color'' must be a scalar specifying a valid ' + $
      'long integer decomposed color. Use aurorax_get_decomposed_color to obtain color ' + $
      'integer from RGB triple.'
    goto, error
  endif
  if not isa(thick, /scalar, /number) or thick lt 0 then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''thick'' must be a positive integer ' + $
      'specifying the contour thickness.'
    goto, error
  endif
  if not isa(symsize, /scalar, /number) or symsize lt 0 then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''symsize'' must be a positive integer.'
    goto, error
  endif
  if not isa(linestyle, /scalar, /number) or linestyle lt 0 or linestyle gt 6 then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''linestyle'' must be an integer ' + $
      'from 0-6. (See IDL built-in linestyles).'
    goto, error
  endif
  if not isa(symbol, /scalar, /number) or linestyle lt 0 or linestyle gt 6 then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''symbol'' must be an integer ' + $
      'from 0-10. (See IDL built-in psym).'
    goto, error
  endif
  
  ; If date is supplied for magnetic transformations, check correct format
  if keyword_set(aacgm_date) then begin
    if ~isa(aacgm_date, /string, /scalar) then begin
      print, '[aurorax_mosaic_plot_contour] Error: keyword ''aacgm_date'' should be a scalar string in the format "YYYY-MM-DD"'
      goto, error
    endif
    if (strlen(aacgm_date) ne 10) or (strmid(aacgm_date,4,1) ne '-') or (strmid(aacgm_date,7,1) ne '-') then begin
      print, '[aurorax_mosaic_plot_contour] Error: keyword ''aacgm_date'' should be a scalar string in the format "YYYY-MM-DD"'
      goto, error
    endif
  endif
    
  ; set default height for aacgm transformations if not supplied
  if ~ keyword_set(aacgm_height) then begin
    aacgm_height = 0.0
  endif
  
  ; Replace the period symbol with a better circle symbol
  if symbol eq 2 then begin
    a = findgen(32) * (!pi * 2 / 32.)
    usersym, cos(a), sin(a), /fill
  endif

  ; Check that at least one of lats or lons is supplied
  if not keyword_set(constant_lons) and not keyword_set(constant_lats) and not keyword_set(point) then begin
    print, '[aurorax_mosaic_plot_contour] Error: At least one of ''constant_lons'' ' + $
      ', ''constant_lats'', or ''point'', must be supplied.'
    goto, error
  endif

  ; Check that constant lons is a number or array of numbers
  if keyword_set(constant_lons) and not isa(constant_lons, /number) then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''constant_lons'' must be a number ' + $
      'or an array of numbers.'
    goto, error
  endif

  ; Check that constant lats is a number or array of numbers
  if keyword_set(constant_lats) and not isa(constant_lats, /number) then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''constant_lats'' must be a number ' + $
      'or an array of numbers.'
    goto, error
  endif

  ; Check that point is a single point
  if keyword_set(point) and not isa(point, /array, /number) then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''point'' must be a 2-element ' + $
      'array of numbers giving [lon, lat].'
    goto, error
  endif
  if keyword_set(point) and n_elements(point) ne 2 then begin
    print, '[aurorax_mosaic_plot_contour] Error: ''point'' must be a 2-element ' + $
      'array of numbers giving [lon, lat].'
    goto, error
  endif
  
  ; Set AACGM date variable if inputs are in AACGM coords
  if keyword_set(mag) then begin
    if keyword_set(aacgm_date) then begin
      aacgm_yy = fix(strmid(aacgm_date,0,4))
      aacgm_mm = fix(strmid(aacgm_date,5,2))
      aacgm_dd = fix(strmid(aacgm_date,8,2))
      !null = aacgm_v2_setdatetime(aacgm_yy, aacgm_mm, aacgm_dd)
    endif else begin
      !null = aacgm_v2_setnow()
    endelse
  endif
  
  ; Plot the single point if provided
  if keyword_set(point) then begin
    ; convert to geographic if input is in magnetic coords
    if keyword_set(mag) then begin
      geo_pos = cnvcoord_v2(point[1], point[0], aacgm_height, /geo)
      point = [geo_pos[1], geo_pos[0]]
    endif
    ; Default to a circle point
    if symbol eq 0 then begin
      a = findgen(32) * (!pi * 2 / 32.)
      usersym, cos(a), sin(a), /fill
      symbol = 8
    endif
    plots, point[0], point[1], color = color, psym = symbol, symsize = symsize
  endif

  ; Iterate through any constant_lons provided
  if keyword_set(constant_lons) then begin
    if isa(constant_lons, /scalar) then constant_lons = [constant_lons]

    for i = 0, n_elements(constant_lons) - 1 do begin
      lon = constant_lons[i]

      ; Generate arrays defining this line of constant lon
      lats = findgen(180 / 0.1) * 0.1 - 90.
      lons = lats * 0 + lon
      
      ; convert to geographic if input is in magnetic coords
      if keyword_set(mag) then begin
        geo_pos = cnvcoord_v2(transpose([[lats], [lons], [replicate(aacgm_height, n_elements(lons))]]), /geo)
        lons = reform(geo_pos[1,*])
        lats = reform(geo_pos[0,*])
      endif
      
      plots, lons, lats, color = color, psym = symbol, linestyle = linestyle, symsize = symsize, thick = thick
    endfor
  endif

  ; Iterate through any constant_lats provided
  if keyword_set(constant_lats) then begin
    if isa(constant_lats, /scalar) then constant_lats = [constant_lats]

    for i = 0, n_elements(constant_lats) - 1 do begin
      lat = constant_lats[i]

      ; Generate arrays defining this line of constant lon
      lons = findgen(360 / 0.05) * 0.05 - 180.
      lats = lons * 0 + lat
      
      ; convert to geographic if input is in magnetic coords
      if keyword_set(mag) then begin
        geo_pos = cnvcoord_v2(transpose([[lats], [lons], [replicate(aacgm_height, n_elements(lons))]]), /geo)
        lons = reform(geo_pos[1,*])
        lats = reform(geo_pos[0,*])
      endif
      
      plots, lons, lats, color = color, psym = symbol, linestyle = linestyle, symsize = symsize, thick = thick
    endfor
  endif
  error:
  device, decomposed = old_decomp
end
