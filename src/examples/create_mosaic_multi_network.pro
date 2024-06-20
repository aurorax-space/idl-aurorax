

pro create_mosaic_multi_network
    
    ; First get image data

    ; start by obtaining lists of all image data objects, seperated by altitude
    data_list_110km = list()
    data_list_230km = list()

    foreach site, ['yknf', 'gill', 'rabb', 'luck'] do begin
        f = file_search("\\bender.phys.ucalgary.ca\data\trex\rgb\stream0\2023\02\24\"+site+"*\ut06\20230224_0615_"+site+"*_full.h5")
        trex_imager_readfile, f, img, meta
        image_data = {data:img, timestamp:meta.EXPOSURE_START_STRING, metadata:meta}
        data_list_110km.add, image_data ; add to list
    endforeach
    foreach site, ['fsmi', 'atha'] do begin
        f = file_search("\\bender.phys.ucalgary.ca\data\themis\imager\stream0\2023\02\24\"+site+"*\ut06\20230224_0615_"+site+"*_full.pgm.gz")
        trex_imager_readfile, f, img, meta
        image_data = {data:img, timestamp:meta.EXPOSURE_START_STRING, metadata:meta}
        data_list_110km.add, image_data
    endforeach

    foreach site, ['rank'] do begin
        f = file_search("\\bender.phys.ucalgary.ca\data\go\rego\stream0\2023\02\24\"+site+"*\ut06\20230224_0615_"+site+"*_6300.pgm.gz")
        trex_imager_readfile, f, img, meta
        image_data = {data:img, timestamp:meta.EXPOSURE_START_STRING, metadata:meta}
        data_list_230km.add, image_data
    endforeach

    prepped_data_110km = aurorax_mosaic_prep_images(data_list_110km)
    prepped_data_230km = aurorax_mosaic_prep_images(data_list_230km)
    prepped_data = [prepped_data_230km, prepped_data_110km]

    ; next get lists of all skymaps in same order
    skymap_list_110km = list()
    skymap_list_230km = list()
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\yknf\yknf_20230114\rgb_skymap_yknf_20230114-+_v01.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\gill\gill_20221102\rgb_skymap_gill_20221102-+_v01.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\rabb\rabb_20220301\rgb_skymap_rabb_20220301-+_v01.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\trex\rgb\skymaps\luck\luck_20220406\rgb_skymap_luck_20220406-+_v01.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\fsmi\fsmi_20220309\themis_skymap_fsmi_20220309-+_v02.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\themis\imager\skymaps\atha\atha_20230115\themis_skymap_atha_20230115-+_v02.sav"
    skymap_list_110km.add, skymap
    restore, "\\bender.phys.ucalgary.ca\data\go\rego\skymap\rank\rank_20221214\rego_skymap_rank_20221214-+_v01.sav"
    skymap_list_230km.add, skymap

    prepped_skymap_110km = aurorax_mosaic_prep_skymap(skymap_list_110km, 110)
    prepped_skymap_230km = aurorax_mosaic_prep_skymap(skymap_list_230km, 230)
    prepped_skymap = [prepped_skymap_230km, prepped_skymap_110km]

    land_color = 2963225
    water_color = 0
    border_color = 16777215 & border_thick = 1
    window_bg_color = 16777215

    map_bounds = [40,220,80,290]
    ilon = 255 & ilat = 56

    ; Define plotting window and plot empty map
    window, 0, xsize=800, ysize=600, xpos=2400
    map_win_loc = [0., 0., 1., 1.]
    device, decomposed=1
    polyfill, [0.,0.,1.,1.], [0.,1.,1.,0.], color=window_bg_color, /normal
    polyfill, [map_win_loc[0],map_win_loc[2],map_win_loc[2],map_win_loc[0]], [map_win_loc[1],map_win_loc[1],map_win_loc[3],map_win_loc[3]], color=water_color, /normal
    map_set, ilat, ilon, 0, sat_p=[20,0,0], /satellite, limit=map_bounds, position=map_win_loc, /noerase, /noborder ; <---- (Change Projection)
    map_continents, /fill, /countries, color=land_color
    map_continents, /countries, color=border_color, thick=border_thick
    map_continents, color=border_color, thick=border_thick

    scale = hash("yknf", [10, 105],$      ; RGB sites
        "gill", [10, 105],$
        "rabb", [10, 105],$
        "luck", [10, 105],$
        "atha", [3500, 14000],$  ; THEMIS sites
        "fsmi", [3500, 14000],$
        "rank", [250, 1500])     ; REGO site

    !null = aurorax_mosaic_create(prepped_data, prepped_skymap, 0, min_elevation=[10,5], intensity_scales=scale, colortable=[3,0])
    
end

