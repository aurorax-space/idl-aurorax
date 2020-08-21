PRO sample_search
  print, "Testing ephemeris upload"
  
  start_timestamp = '2019-01-01T00:00:00'
  end_timestamp = '2019-01-01T00:10:00'
  instrument = {programs: ['swarm'], platforms: ['swarma', 'swarmb'], instrument_types: ['ssc-web']}
  
  result = aurorax_ephemeris_search(start_timestamp, end_timestamp, instrument) 

  print, tag_names(result(0)), result(0)
  
END