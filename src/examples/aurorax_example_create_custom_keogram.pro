

pro aurorax_example_create_custom_keogram
<<<<<<< Updated upstream

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
=======
    
    ; First, download and read an hour of TREx RGB data
    d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2021-11-04T03:00:00', '2021-11-04T03:59:59', site_uid="gill")
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    
    ; Download and read the corresponding skymap
    ; Download all skymaps in 3 years leading up to date of interest
    d = aurorax_ucalgary_download('TREX_RGB_SKYMAP_IDLSAV', '2018-11-04T03:00:00', '2021-11-04T03:59:59', site_uid='gill')

    ; Read in all of the skymaps that were found
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    
    ; Grab the *last* skymap out of the skymap data struct as this is most recent to date of interest
    skymap = skymap_data.data[-1]
    
    ; Now extract the image array and timestamps from the image data structure
    img = image_data.data
    time_stamp = image_data.timestamp
    
    ; Define some lats/lons that define the keogram slice of interest
    latitudes = findgen(50, start=51, increment=0.22)
    longitudes = -102.0 + 5 * sin(!pi * (latitudes - 51.0) / (62.0 - 51.0))
    
    ; Create the custom keogram along the above defined lats/lons
    keo = aurorax_keogram_create_custom(img, time_stamp, "geo", longitudes, latitudes, /show_preview, skymap=skymap, altitude_km=113)
    
    ; Display the keogram, using aspect ratio to manually stretch the height, as the resuling
    ; keogram will be quite short, as we sampled 50 data points, giving a height of only 49 pixels
    aurorax_keogram_plot, keo, title="Custom Keogram", location=[0,0], dimensions=[1000,400], aspect_ratio=12
>>>>>>> Stashed changes
end