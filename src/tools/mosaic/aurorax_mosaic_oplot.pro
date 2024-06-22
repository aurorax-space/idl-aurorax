pro aurorax_mosaic_oplot, constant_lons=constant_lons, constant_lats=constant_lats, point=point, color=color, thick=thick, linestyle=linestyle, symbol=symbol, symsize=symsize
    
    device, get_decomposed=old_decomp
    device, decomposed=1
    
    if keyword_set(mag) then begin
        print, "[aurorax_mosaic_plot_contour] Error: Magnetic coordinates are not " + $
               "currently supported for this procedure."
        goto, error
    endif
    
    ; Set default values
    if not isa(color) then color = 0
    if not isa(thick) then thick = 1
    if not isa(linestyle) then linestyle = 0
    if not isa(symbol) then symbol = 0
    if not isa(symsize) then symsize = 1
    
    ; Make sure that all plot parameters are accepted
    if not isa(color, /scalar, /number) or color lt 0 or color gt aurorax_get_decomposed_color([255,255,255]) then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'color' must be a scalar specifying a valid " + $
               "long integer decomposed color. Use aurorax_get_decomposed_color to obtain color " + $
               "integer from RGB triple."
        goto, error
    endif
    if not isa(thick, /scalar, /number) or thick lt 0 then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'thick' must be a positive integer " + $
               "specifying the contour thickness."
        goto, error
    endif
    if not isa(symsize, /scalar, /number) or symsize lt 0 then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'symsize' must be a positive integer."
        goto, error
    endif
    if not isa(linestyle, /scalar, /number) or linestyle lt 0 or linestyle gt 6 then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'linestyle' must be an integer " + $
               "from 0-6. (See IDL built-in linestyles)."
        goto, error
    endif
    if not isa(symbol, /scalar, /number) or linestyle lt 0 or linestyle gt 6 then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'symbol' must be an integer " + $
            "from 0-10. (See IDL built-in psym)."
        goto, error
    endif
    
    ; Replace the period symbol
    if symbol eq 2 then begin
        a = findgen(32) * (!pi*2/32.)
        userSym, cos(a), sin(a), /fill
    endif
    
    ; Check that at least one of lats or lons is supplied
    if not keyword_set(constant_lons) and not keyword_set(constant_lats) and not keyword_set(point) then begin
        print, "[aurorax_mosaic_plot_contour] Error: At least one of 'constant_lons' " + $
               ", 'constant_lats', or 'point', must be supplied."
        goto, error
    endif
    
    ; Check that constant lons is a number or array of numbers
    if keyword_set(constant_lons) and not isa(constant_lons, /number) then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'constant_lons' must be a number " + $
               "or an array of numbers."
        goto, error
    endif
    
    ; Check that constant lats is a number or array of numbers
    if keyword_set(constant_lats) and not isa(constant_lats, /number) then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'constant_lats' must be a number " + $
               "or an array of numbers."
        goto, error
    endif
    
    ; Check that point is a single point
    if keyword_set(point) and not isa(point, /array, /number) then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'point' must be a 2-element " + $
               "array of numbers."
        goto, error
    endif
    if keyword_set(point) and n_elements(point) ne 2 then begin
        print, "[aurorax_mosaic_plot_contour] Error: 'point' must be a 2-element " + $
            "array of numbers."
        goto, error
    endif
    
    ; Plot the single point if provided
    if keyword_set(point) then begin
        ; Default to a circle point
        if symbol eq 0 then begin
            a = findgen(32) * (!pi*2/32.)
            userSym, cos(a), sin(a), /fill
            symbol = 8
        endif
        plots, point[0], point[1], color=color, psym=symbol, symsize=symsize
    endif
    
    ; Iterate through any constant_lons provided
    if keyword_set(constant_lons) then begin
        if isa(constant_lons, /scalar) then constant_lons = [constant_lons]
        
        for i=0, n_elements(constant_lons)-1 do begin
            lon = constant_lons[i]
            
            ; Generate arrays defining this line of constant lon
            lats = findgen(180/0.1)*0.1 - 90.
            lons = lats * 0 + lon
            
            plots, lons, lats, color=color, psym=symbol, linestyle=linestyle, symsize=symsize
        endfor
    endif
    
    ; Iterate through any constant_lats provided
    if keyword_set(constant_lats) then begin
        if isa(constant_lats, /scalar) then constant_lats = [constant_lats]

        for i=0, n_elements(constant_lats)-1 do begin
            lat = constant_lats[i]

            ; Generate arrays defining this line of constant lon
            lons = findgen(360/0.05)*0.05 - 180.
            lats = lons * 0 + lat

            plots, lons, lats, color=color, psym=symbol, linestyle=linestyle, symsize=symsize
        endfor
    endif
    error:
    device, decomposed=old_decomp
end