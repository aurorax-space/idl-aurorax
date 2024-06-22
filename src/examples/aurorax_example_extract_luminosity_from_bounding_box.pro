


pro aurorax_example_extract_luminosity_from_bounding_box
    
    ; Download an hour of TREx RGB data
    d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2021-11-04T03:00:00', '2021-11-04T03:59:59', site_uid='gill')

    ; Read the image data
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    
    ; Download all skymaps in 3 years leading up to date of interest
    d = aurorax_ucalgary_download('TREX_RGB_SKYMAP_IDLSAV', '2018-11-04T03:00:00', '2021-11-04T03:59:59', site_uid='gill')
    
    ; Read in all of the skymaps that were found
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    
    ; Get images and timestamp arrays from the image data object
    images = image_data.data
    timestamps = image_data.timestamp
    
    ; Grab the *last* skymap out of the skymap data struct as this is most recent to date of interest
    skymap = skymap_data.data[-1]

    ; Extract some data within bounds of azimuth, CCD, elevation, and geo lats
    azim_bounds = [134, 143]
    luminosity_in_azim = aurorax_bounding_box_extract_metric(images, "azim", azim_bounds, skymap=skymap, /show_preview)
    
    ccd_bounds = [140, 173, 140, 160]
    luminosity_in_ccd = aurorax_bounding_box_extract_metric(images, "ccd", ccd_bounds, skymap=skymap, /show_preview)
    
    elev_bounds = [40,60]
    luminosity_in_elev = aurorax_bounding_box_extract_metric(images, "elev", elev_bounds, skymap=skymap, /show_preview)
    
    ; For this one, lets get the mean, using the metric keyword. By default, the median
    ; is returned, but one can also obtain the mean or sum of data within the desired bounds.
    geo_bounds = [-94, -95, 55, 55.5]
    luminosity_in_geo = aurorax_bounding_box_extract_metric(images, "geo", geo_bounds, metric="mean", skymap=skymap, altitude_km=112, /show_preview)
    
    ; Let's plot the data exctracted from the RGB images withing the geo bounds. 
    ; For multi channel image data, the metric will be returned for each channel.
    p = plot(reform(luminosity_in_geo[0,*]), color='red')
    p = plot(reform(luminosity_in_geo[1,*]), color='green', /overplot)
    p = plot(reform(luminosity_in_geo[2,*]), color='blue', /overplot)
    
end