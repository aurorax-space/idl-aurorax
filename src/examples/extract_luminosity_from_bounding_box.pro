


pro extract_luminosity_from_bounding_box
    
    ; First, obtain 1 hour of data
    f = file_search("\\bender.phys.ucalgary.ca\data\trex\rgb\stream0\2021\11\04\gill*\ut03\20211104_03*_gill*_full.h5")
    trex_imager_readfile, f, img, meta
    image_data = {data:img, timestamp:meta.EXPOSURE_START_STRING, metadata:meta}
    im = image(img[*,*,*,0])

    ; Load in corresponding skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\gill\gill_20210726\rgb_skymap_gill_20210726-+_v01.sav"
    
    ; Get images and timestamp arrays from the image data object
    images = image_data.data
    timestamps = image_data.timestamp
    
    luminosity = aurorax_bounding_box_extract_metric(images, "geo", [-94, -95, 55, 55.5], skymap=skymap, altitude_km=110, /show_preview)
    
    p = plot(reform(luminosity[0,*]), color='red')
    p = plot(reform(luminosity[1,*]), color='green', /overplot)
    p = plot(reform(luminosity[2,*]), color='blue', /overplot)
    
end