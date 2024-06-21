

pro aurorax_example_create_keogram_trex_rgb
    
    ; First, obtain 1 hour of data
    f = file_search("\\bender.phys.ucalgary.ca\data\trex\rgb\stream0\2023\02\24\yknf*\ut06\20230224_06*_yknf*_full.h5")
    trex_imager_readfile, f, img, meta
    time_stamp = meta.EXPOSURE_START_STRING
    
    ; Load in corresponding skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\yknf\yknf_20230114\rgb_skymap_yknf_20230114-+_v01.sav"
    
    ; Create keogram object
    keo = aurorax_keogram_create(img, time_stamp)
    
    ; Extract keogram data array. - This can be further manipulated or plotted however you'd like
    keo_arr = keo.data
    
    ; Add geographic, magnetic, and elevation axes to the keogram object
    keo = aurorax_keogram_add_axis(keo, skymap, /geo, /mag, /elev, altitude_km=110)
    
    ; Plot with aurorax function
    !null = aurorax_keogram_plot(keo, title="Geographic", /geo, location=[0,0], dimensions=[900,400])
    !null = aurorax_keogram_plot(keo, title="Elevation", /elev, location=[0,420], dimensions=[900,400])

end