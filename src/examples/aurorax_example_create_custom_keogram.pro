


pro aurorax_example_create_custom_keogram
    
    ; First, obtain 1 hour of data
    print, "Reading Files..."
    f = file_search("\\bender.phys.ucalgary.ca\data\trex\rgb\stream0\2021\11\04\gill*\ut03\20211104_033*_gill*_full.h5")
    trex_imager_readfile, f, img, meta
    time_stamp = meta.EXPOSURE_START_STRING
    print, "Finished Reading."
    
    ; Load in corresponding skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\gill\gill_20210726\rgb_skymap_gill_20210726-+_v01.sav"
    
    latitudes = findgen(50, start=51, increment=0.22)
    longitudes = -102.0 + 5 * sin(!pi * (latitudes - 51.0) / (62.0 - 51.0))
    
    !null = aurorax_keogram_create_custom(img, time_stamp, "geo", longitudes, latitudes, /show_preview, skymap=skymap, altitude_km=113)
end