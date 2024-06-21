pro aurorax_example_download_data
  ; download an hour of THEMIS ASI data
  ;
  ; using the aurorax_list_datasets() function, we figured out that
  ; the dataset names we want to use
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW','2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='atha')
  help,d
  print,''

  ; download with no output
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW','2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='atha',/quiet)
  print,''

  ; download one minute of data from all sites
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL','2022-01-01T06:00:00','2022-01-01T06:00:00')
  print,''

  ; download force redownload of data, even if it exists locally already
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL','2022-01-01T06:00:00','2022-01-01T06:00:00',/overwrite)
  print,''
end