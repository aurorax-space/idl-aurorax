pro aurorax_example_read_data
  ; get dataset
  dataset = (aurorax_list_datasets(name='TREX_RGB_RAW_NOMINAL'))[0]

  ; download an hour of THEMIS ASI data
  d = aurorax_download_data(dataset.name,'2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='gill')

  ; set list of files to read
  f = d.filenames

  ; read the data
  data = aurorax_read_data(dataset,f)
  help,data

  ; read the data quietly
  data = aurorax_read_data(dataset,f[0],/quiet)
end