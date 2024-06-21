pro aurorax_example_read_data
  ; download an hour of THEMIS ASI data
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW','2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='gill')

  ; set list of files to read
  f = d.filenames

  ; read the data
  data = aurorax_ucalgary_read(d.dataset,f)
  help,data

  ; read the data quietly
  data = aurorax_ucalgary_read(d.dataset,f[0],/quiet)
end