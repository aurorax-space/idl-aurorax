

pro aurorax_example_create_mosaic_themis

    ; First get image data

    ; start by obtaining a list of all image data objects
    data_list_110km = list()

    foreach site, ["atha", "fsmi", "gill", "inuv", "talo"] do begin
        f = file_search("\\bender.phys.ucalgary.ca\data\themis\imager\stream0\2023\02\24\"+site+"*\ut06\20230224_0640_"+site+"*_full.pgm.gz")
        trex_imager_readfile, f, img, meta
        image_data = {data:img, timestamp:meta.EXPOSURE_START_STRING, metadata:meta}
        data_list_110km.add, image_data ; add to list
    endforeach

    prepped_data_110km = aurorax_mosaic_prep_images(data_list_110km)

    ; next get lists of all skymaps in same order
    skymap_list_110km = list()
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\atha\atha_20230115\themis_skymap_atha_20230115-+_v02.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\fsmi\fsmi_20230321\themis_skymap_fsmi_20230321-+_v02.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\gill\gill_20230220\themis_skymap_gill_20230220-+_v02.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\inuv\inuv_20230312\themis_skymap_inuv_20230312-+_v02.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\talo\talo_20230214\themis_skymap_talo_20230214-+_v02.sav"
    skymap_list_110km.add, skymap

    prepped_skymap_110km = aurorax_mosaic_prep_skymap(skymap_list_110km, 117)
    
    ; Set up window for direct graphics plotting, with empty map
    land_color = 2963225
    water_color = 0
    border_color = 16777215 & border_thick = 1
    window_bg_color = 16777215

    map_bounds = [40,220,80,290]
    ilon = 255 & ilat = 56

    window, 0, xsize=800, ysize=600, xpos=2400
    map_win_loc = [0., 0., 1., 1.]
    device, decomposed=1
    polyfill, [0.,0.,1.,1.], [0.,1.,1.,0.], color=window_bg_color, /normal
    polyfill, [map_win_loc[0],map_win_loc[2],map_win_loc[2],map_win_loc[0]], [map_win_loc[1],map_win_loc[1],map_win_loc[3],map_win_loc[3]], color=water_color, /normal
    map_set, ilat, ilon, 0, sat_p=[20,0,0], /satellite, limit=map_bounds, position=map_win_loc, /noerase, /noborder ; <---- (Change Projection)
    map_continents, /fill, /countries, color=land_color
    map_continents, /countries, color=border_color, thick=border_thick
    map_continents, color=border_color, thick=border_thick
    
    ; set scaling bounds
    scale = hash("fsmi", [2000, 10000],$
                 "inuv", [2000, 5500],$
                 "atha", [2000, 6000],$
                 "gill", [2000, 10000],$
                 "talo", [2000, 6000])    

    !null = aurorax_mosaic_create(prepped_data_110km, prepped_skymap_110km, 0, intensity_scales=scale, colortable=0)

end

