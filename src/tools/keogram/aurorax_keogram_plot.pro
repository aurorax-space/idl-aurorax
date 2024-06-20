

function aurorax_keogram_plot, keogram_struct, object=object, geo=geo, mag=mag, elev=elev, dimensions=dimensions, location=location, title=title, x_tick_interval=x_tick_interval, y_tick_interval=y_tick_interval
    
    axis_keywords = [keyword_set(geo), keyword_set(mag), keyword_set(elev)]
    if total(axis_keywords) gt 1 then stop, "(aurorax_keogram_plot) Error: Only one of '/geo', '/mag', '/elev' may be set"
    
    ; Make sure desired axis exists
    if keyword_set(geo) and where("GEO_Y" eq tag_names(keogram_struct), /null) eq !null then begin
        stop, "(aurorax_keogram_plot) Error: Keyword '/geo' was set, but input keogram has no geographic axis. Use aurorax_keogram_add_axis()."
    endif
    if keyword_set(mag) and where("MAG_Y" eq tag_names(keogram_struct), /null) eq !null then begin
        stop, "(aurorax_keogram_plot) Error: Keyword '/mag' was set, but input keogram has no magnetic axis. Use aurorax_keogram_add_axis()."
    endif
    if keyword_set(elev) and where("ELEV_Y" eq tag_names(keogram_struct), /null) eq !null then begin
        stop, "(aurorax_keogram_plot) Error: Keyword '/elev' was set, but input keogram has no elevation axis. Use aurorax_keogram_add_axis()."
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
    keo_arr = keogram_struct.data
    
    ; Get number of channels
    if n_elements(size(keo_arr, /dimensions)) eq 3 then begin
        n_channels = (size(keo_arr, /dimensions))[0]
    endif else begin
        n_channels = 1
    endelse
    
    ; Get dimensions of keogram
    if n_channels eq 1 then begin
        keo_width = (size(keo_arr, /dimensions))[0]
        keo_height = (size(keo_arr, /dimensions))[1]
    endif else begin
        keo_width = (size(keo_arr, /dimensions))[1]
        keo_height = (size(keo_arr, /dimensions))[2]
    endelse
    
    if not keyword_set(dimensions) then dimensions = [keo_width+100,keo_height+100]
    if not keyword_set(location) then dimensions = [0,0]
    if not isa(x_tick_interval) then x_tick_interval = 200
    if not isa(y_tick_interval) then y_tick_interval = 50

    
    ; Create the plot
    w = window(dimensions = dimensions, location=location)
    keo_image = image(keo_arr, /current)
    if keyword_set(title) and isa(title, /string) then keo_image.title = title
    
    ; Create the x axis (time)
    timestamp_axis = []
    for i=0, n_elements(keogram_struct.timestamp)-1, x_tick_interval do begin
        timestamp_axis = [timestamp_axis, strmid(keogram_struct.timestamp[i], 11, 5)]
    endfor
    timestamp_axis = [timestamp_axis, strmid(keogram_struct.timestamp[-1], 11, 5)]
    x_axis = axis('X', location=0)
    x_axis.tickinterval = x_tick_interval
    x_axis.tickname = timestamp_axis
    x_axis.title = "Time (UTC)"
    x_axis.text_orientation = 20

    ; Create desired y-axis
    coord_axis = []
    for i=0, n_elements(y)-1, y_tick_interval do begin
        if y[i] eq !values.f_nan then begin
            coord_axis = [coord_axis, '']
        endif else begin
            coord_axis = [coord_axis, strmid(strcompress(string(y[i]),/remove_all),0,4)]
        endelse
        
    endfor
    y_title = (["Geographic Latitude", "Magnetic Latitude", "Elevation", "CCD Y"])[where(axis_keywords)]
    y_axis = axis('Y', location=0)
    y_axis.tickinterval = y_tick_interval
    y_axis.tickname = coord_axis
    y_axis.title = y_title
        
end

