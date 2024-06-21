

function aurorax_keogram_create, images, time_stamp
    
    if not isa(images, /array) then stop, "(aurorax_keogram_create) Error: 'images' must be an array"  

    ; Get the number of channels of image data
    images_shape = size(images, /dimensions)
    if n_elements(images_shape) eq 2 then begin
        stop, "(aurorax_keogram_create) Error: 'images' must contain multiple frames."
    endif else if n_elements(images_shape) eq 3 then begin
        if images_shape[0] eq 3 then stop, "(aurorax_keogram_create) Error: 'images' must contain multiple frames."
        n_channels = 1
    endif else if n_elements(images_shape) eq 4 then begin
        n_channels = images_shape[0]
    endif else stop, "(aurorax_keogram_create) Error: Unable to determine number of channels based on the supplied images. " + $ 
                     "Make sure you are supplying a [cols,rows,images] or [channels,cols,rows,images] sized array."
    
    ; Extract the keogram slice, transpose and reshape for proper output shape
    if n_channels eq 1 then begin
        keo_idx = images_shape[0] / 2
        keo_arr = transpose(reform(images[keo_idx,*,*]))
    endif else begin
        keo_idx = images_shape[1] / 2
        keo_arr = reform(images[*,keo_idx,*,*])
        keo_arr = bytscl(transpose(keo_arr, [0,2,1]), min=0, max=255)
    endelse
    
    ; Create CCD Y axis
    if n_channels eq 1 then begin
        ccd_y = indgen((size(keo_arr, /dimensions))[1])
    endif else begin
        ccd_y = indgen((size(keo_arr, /dimensions))[2])
    endelse
    
    ; Return keogram array
    return, {data:keo_arr, ccd_y:ccd_y, slice_idx:keo_idx, timestamp:time_stamp}
        
end
