function aurorax_calibrate_rego, images, cal_flatfield=cal_flatfield, cal_rayleighs=cal_rayleighs, exposure_length_sec=exposure_length_sec, no_dark_subtract=no_dark_subtract
    
    calibrated_images = images
    
    ; Default exposure of 2 seconds
    if not keyword_set(exposure_length_sec) then exposure_length_sec = 2.0
    
    ; Skip dark frame subtraction if desired
    if keyword_set(no_dark_subtract) then goto, skip_dark_frame
    
    ; Perform dark frame subtraction
    calibrated_images = __perform_dark_frame_calibration(calibrated_images, 5)
    skip_dark_frame:
    
    ; Skip flatfield calibration if desired
    if not keyword_set(cal_flatfield) then goto, skip_cal_flatfield

    ; Perform flatfield calibration
    calibrated_images = __perform_flatfield_calibration(calibrated_images, cal_flatfield)   
    skip_cal_flatfield:

    ; Skip rayleighs calibration if desired
    if not keyword_set(cal_rayleighs) then goto, skip_cal_rayleighs
    
    ; Perform flatfield calibration
    calibrated_images = __perform_rayleighs_calibration(calibrated_images, cal_rayleighs, exposure_length_sec)
    skip_cal_rayleighs:

    return, calibrated_images
end