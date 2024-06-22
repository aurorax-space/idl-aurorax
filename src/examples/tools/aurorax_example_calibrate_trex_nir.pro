pro aurorax_example_calibrate_trex_nir

    ; First, download and read an hour of TREx NIR data
    d = aurorax_ucalgary_download('TREX_NIR_RAW', '2021-11-04T01:00:00', '2021-11-04T01:59:59', site_uid="rabb")
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

    ; Download and read flatfield calibration files. We search for any calibration files
    ; in the years leading up to the date of interest and then use the most recent.
    dataset_name = "TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV"
    start_search_ts = '2010-11-04T01:00:00'
    device_uid = "217"
    d = aurorax_ucalgary_download(dataset_name, start_search_ts, '2021-11-04T01:00:00', device_uid=device_uid)
    flatfield_cal = (aurorax_ucalgary_read(d.dataset, d.filenames))[-1].data[0]

    ; Repeat the above process for Rayleighs calibration
    dataset_name = "TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV"
    start_search_ts = '2010-11-04T01:00:00'
    device_uid = "217"
    d = aurorax_ucalgary_download(dataset_name, start_search_ts, '2021-11-04T01:00:00', device_uid=device_uid)
    rayleighs_cal = (aurorax_ucalgary_read(d.dataset, d.filenames))[-1].data[0]

    ; Calibrate the image data - note that dark frame is subtracted automatically unless /no_dark_subtract is passed
    images = image_data.data
    calibrated_images = aurorax_calibrate_trex_nir(images, cal_flatfield=flatfield_cal, cal_rayleighs = rayleighs_cal)

    ; Plot before and after calibration
    raw_im = image(images[*,*,270], title="Raw Image", location=[5,5], rgb_table=7, dimensions=[400,400])
    cal_im = image(calibrated_images[*,*,270], title="Calibrated Image (Rayleighs)", location=[517,5], rgb_table=7, dimensions=[400,400])
end