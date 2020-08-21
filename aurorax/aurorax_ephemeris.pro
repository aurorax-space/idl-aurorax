FUNCTION aurorax_ephemeris_sources

  netUrl = OBJ_NEW('IDLnetURL')

  AURORAX_SOURCES_URL = "http://api.staging.aurorax.space:8080/api/v1/ephemeris-sources"

  result_string = netUrl->Get(/STRING_ARRAY, URL=SOURCES_URL)
  
  json_object = JSON_PARSE(result_string, /TOSTRUCT)
  RETURN, json_object
  
END

FUNCTION aurorax_process_record, record_struct
  PRINT, "Processing record"
  AACGM_v2_DAT_PREFIX="C:\Users\Maryam\Desktop\aurorax\idl_library\aacgm_coefficients\aacgm_coeffs-13-"
  IGRF_COEFFS="C:\Users\Maryam\Desktop\aurorax\idl_library\aacgm\magmodel_1590-2020.txt"
END

FUNCTION aurorax_upload_ephemeris, data, metadata
  AURORAX_UPLOAD_URL = "http://api.staging.aurorax.space:8080/api/v1/ephemeris-sources/{identifier}/ephemeris"
  
  PRINT, "Uploading ephemeris record(s)"
END

FUNCTION aurorax_ephemeris_search, start_timestamp, end_timestamp, instrument
  AURORAX_SEARCH_URL = "http://api.staging.aurorax.space:8080/api/v1/ephemeris/search"
  
  search_params = {start:start_timestamp, aurorax_end_t:end_timestamp}

  tn = tag_names(instrument)
  
  IF where(tn eq 'PROGRAMS') ne -1 THEN BEGIN
    programs_list = [instrument.programs]
    aurorax_ephemeris_search_sources = CREATE_STRUCT('programs', programs_list)
  ENDIF
  
  IF where(tn eq 'PLATFORMS') ne -1 THEN BEGIN
    platforms_list = [instrument.platforms]
    aurorax_ephemeris_search_sources = CREATE_STRUCT('platforms', platforms_list, aurorax_ephemeris_search_sources)
  ENDIF
  
  IF where(tn eq 'INSTRUMENT_TYPES') ne -1 THEN BEGIN
    instrument_types_list = [instrument.instrument_types]
    aurorax_ephemeris_search_sources = CREATE_STRUCT('instrument_types', instrument_types_list, aurorax_ephemeris_search_sources)
  ENDIF
  
  IF where(tn eq 'METADATA_FILTERS') ne -1 THEN BEGIN
    metadata_list = [instrument.metadata_filters]
    aurorax_ephemeris_search_sources = CREATE_STRUCT('metadata_filters', metadata_filters_list_list, aurorax_ephemeris_search_sources)
  ENDIF

  search_params = create_struct('ephemeris_sources', aurorax_ephemeris_search_sources, search_params)

  string_search_params = json_serialize(search_params, /LOWERCASE)
  string_search_params = string_search_params.Replace('aurorax_end_t', 'end')
  print, string_search_params
  
  netUrl = OBJ_NEW('IDLnetURL')
  netUrl->SetProperty, HEADERS = 'Content-Type: application/json'
  
  string_search_result = netUrl->Put(string_search_params, /BUFFER, /POST, /STRING_ARRAY, URL=AURORAX_SEARCH_URL)
  search_result = json_parse(string_search_result, /TOSTRUCT)
  
  return, search_result.ephemeris_data
  
END