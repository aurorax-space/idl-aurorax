

pro aurorax_example_create_mosaic_themis


    ; Create lists to hold all image data and skymap structures
    data_list = list()
    skymap_list = list()
    
    ; Date of Interest
    date_time = '2021-11-04T09:30:00'

    ; Date to search back to for skymaps
    earliest_date_time = '2017-02-24T06:15:00'
    
    foreach site, ["atha", "fsmi", "fsim", "pina", "talo", "tpas"] do begin
        ; download and read data for this site, then add to respective list
        d = aurorax_ucalgary_download('THEMIS_ASI_RAW', date_time, date_time, site_uid=site)
        image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
        data_list.add, image_data
        
        ; download all skymaps in range, read them in, then append *most recent* to respective list
        d = aurorax_ucalgary_download('THEMIS_ASI_SKYMAP_IDLSAV', earliest_date_time, date_time, site_uid=site)
        skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
        skymap_list.add, skymap_data.data[-1]
    endforeach
    
    ; set altitude in km
    altitude = 115 
    
    ; Prep the images and skymaps for plotting
    prepped_data = aurorax_mosaic_prep_images(data_list)
    prepped_skymap = aurorax_mosaic_prep_skymap(skymap_list, altitude)
    
    ; Now, we need to create a direct graphics map that the data can be plotted
    ; onto. Using, the map_set procedure (see IDL docs for info), create the map
    ; however you'd like. Below is an example
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
    
    ; Define scaling bounds for image data if desiresd
    scale = hash("atha", [2500, 10000],$
                 "fsmi", [2500, 10000],$
                 "fsim", [2500, 12500],$
                 "pina", [2500, 10000],$
                 "talo", [2000, 10000],$
                 "tpas", [2500, 10000])  

    ; Plot the first frame 
    image_idx = 0 
    
    ; Use grey colormap for themis
    ct = 0

    ; Call the mosaic creation function to plot the mosaic in the current window
    aurorax_mosaic_plot, prepped_data, prepped_skymap, image_idx, intensity_scales=scale, colortable=ct

end

