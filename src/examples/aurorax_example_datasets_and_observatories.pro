pro aurorax_example_datasets_and_observatories
  ; list datasets
  datasets = aurorax_list_datasets()
  print,''
  print,'Found ' + strcompress(fix(n_elements(datasets)),/remove_all) + ' datasets when searching with no filter'
  print,''

  ; list datasets with filter
  datasets = aurorax_list_datasets(name='TREX_RGB')
  print,'Found ' + strcompress(fix(n_elements(datasets)),/remove_all) + ' datasets when filtering for "THEMIS_ASI"'
  help,datasets[0]
  print,''
  print,''

  ; list observatories
  observatories = aurorax_list_observatories('themis_asi')
  print,'Found ' + strcompress(fix(n_elements(datasets)),/remove_all) + ' observatories part of the "themis_asi" instrument array'
  print,''

  ; list observatories with filter
  obs_gill = aurorax_list_observatories('trex_rgb', uid='gill')
  print,'Retrieved and displaying the TREx RGB GILL observatory'
  help,obs_gill[0]
  print,''
end