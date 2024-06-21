


pro aurorax_example_extract_luminosity_from_bounding_box
    
    ; First, obtain 1 hour of data
    print, "Reading Files..."
    f = file_search("\\bender.phys.ucalgary.ca\data\trex\rgb\stream0\2021\11\04\gill*\ut03\20211104_03*_gill*_full.h5")
    trex_imager_readfile, f, img, meta

    image_data = {data:img, timestamp:meta.EXPOSURE_START_STRING, metadata:meta}
    print, "Finished Reading."
    
    ; Load in corresponding skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\gill\gill_20210726\rgb_skymap_gill_20210726-+_v01.sav"
    
    ; Get images and timestamp arrays from the image data object
    images = image_data.data
    timestamps = image_data.timestamp
    
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