FUNCTION aurorax_search_conjunctions_single, start_timestamp, end_timestamp, source1, source2, distance, conjunction_type
  PRINT, "Searching for conjunctions"
  
  AURORAX_CONJUNCTIONS_URL = "http://api.staging.aurorax.space:8080/api/v1/conjunctions/search"
  
  conjunction_params = {start:start_timestamp, aurorax_end_t:end_timestamp, max_distance:distance}
  
  ;
  tn1 = tag_names(source1)
  PRINT, tn1
  IF where(tn1 eq 'PROGRAMS') ne -1 THEN BEGIN
    programs_list = [source1.programs]

    aurorax_conjunction_search_source1 = CREATE_STRUCT('programs', programs_list)
  ENDIF

  IF where(tn1 eq 'PLATFORMS') ne -1 THEN BEGIN
    platforms_list = [source1.platforms]

    aurorax_conjunction_search_source1 = CREATE_STRUCT('platforms', platforms_list, aurorax_conjunction_search_source1)
  ENDIF

  IF where(tn1 eq 'INSTRUMENT_TYPES') ne -1 THEN BEGIN
    instrument_types_list = [source1.instrument_types]

    aurorax_conjunction_search_source1 = CREATE_STRUCT('instrument_types', instrument_types_list, aurorax_conjunction_search_source1)
  ENDIF

  IF where(tn1 eq 'METADATA_FILTERS') ne -1 THEN BEGIN
    metadata_list = [source1.metadata_filters]

    aurorax_conjunction_search_source1 = CREATE_STRUCT('metadata_filters', metadata_filters_list_list, aurorax_conjunction_search_source1)
  ENDIF
  PRINT, aurorax_conjunction_search_source1
  
  tn2 = tag_names(source2)
  PRINT, tn2
  IF where(tn2 eq 'PROGRAMS') ne -1 THEN BEGIN
    programs_list = [source2.programs]

    aurorax_conjunction_search_source2 = CREATE_STRUCT('programs', programs_list)
  ENDIF

  IF where(tn2 eq 'PLATFORMS') ne -1 THEN BEGIN
    platforms_list = [source2.platforms]

    aurorax_conjunction_search_source2 = CREATE_STRUCT('platforms', platforms_list, aurorax_conjunction_search_source2)
  ENDIF

  IF where(tn2 eq 'INSTRUMENT_TYPES') ne -1 THEN BEGIN
    instrument_types_list = [source2.instrument_types]

    aurorax_conjunction_search_source2 = CREATE_STRUCT('instrument_types', instrument_types_list, aurorax_conjunction_search_source2)
  ENDIF

  IF where(tn2 eq 'METADATA_FILTERS') ne -1 THEN BEGIN
    metadata_list = [source2.metadata_filters]

    aurorax_conjunction_search_source2 = CREATE_STRUCT('metadata_filters', metadata_filters_list_list, aurorax_conjunction_search_source2)
  ENDIF
  PRINT, aurorax_conjunction_search_source2
  
  aurorax_source_params = {source1:aurorax_conjunction_search_source1, source2:aurorax_conjunction_search_source2}
  conjunction_params = create_struct(aurorax_source_params, conjunction_params)
  ;
  
  
  CASE STRLOWCASE(conjunction_type) of
    "both": conjunction_params = create_struct("conjunction_types", ["nbtrace", "sbtrace"], conjunction_params)
    "south": conjunction_params = create_struct("conjunction_types", ["sbtrace"], conjunction_params)
    "north": conjunction_params = create_struct("conjunction_types", ["nbtrace"], conjunction_params)
    ELSE: PRINT, "Invalid conjunction type"
  ENDCASE
    
  
  RETURN, conjunction_params


END
