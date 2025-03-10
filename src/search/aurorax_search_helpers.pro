; -------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; -------------------------------------------------------------

pro __aurorax_message, msg
  compile_opt hidden

  ; set datetime string
  dt_str = systime()

  ; print message
  print, '[' + dt_str + '] ' + msg
end

function __aurorax_humanize_bytes, bytes
  compile_opt hidden

  ; figure out which of bytes, kilobytes, megabytes, or gigabytes; and then convert it
  if (bytes ge long64(1024) ^ long64(3)) then begin
    bytes_converted = IDLUnit(strtrim(bytes, 2) + ' bytes -> gigabytes')
    converted_str = strtrim(string(bytes_converted.quantity, format = '(f6.2)') + ' GB', 2)
  endif else if (bytes ge long64(1024) ^ long64(2)) then begin
    bytes_converted = IDLUnit(strtrim(bytes, 2) + ' bytes -> megabytes')
    converted_str = strtrim(string(bytes_converted.quantity, format = '(f6.2)') + ' MB', 2)
  endif else if (bytes ge long64(1024)) then begin
    bytes_converted = IDLUnit(strtrim(bytes, 2) + ' bytes -> kilobytes')
    converted_str = strtrim(string(bytes_converted.quantity, format = '(f6.2)') + ' KB', 2)
  endif else begin
    converted_str = strtrim(bytes, 2) + ' bytes'
  endelse

  ; return
  return, converted_str
end

function __aurorax_datetime_parser, input_str, interpret_as_start = start_kw, interpret_as_end = end_kw
  compile_opt hidden

  ; input of a datetime string of various formats, output is a full datetime
  ; string in the YYYY-MM-DDTHH:MM:SS format that will be used by the AuroraX
  ; API as part of requests
  dt_str = ''
  leap_years = [1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040]

  ; set flags
  start_flag = 1
  end_flag = 0
  if keyword_set(start_kw) then begin
    start_flag = 1
    end_flag = 0
  endif
  if keyword_set(end_kw) then begin
    start_flag = 0
    end_flag = 1
  endif

  ; remove some characters (-, /, T)
  input_str = input_str.replace('-', '')
  input_str = input_str.replace('/', '')
  input_str = input_str.replace('T', '')
  input_str = input_str.replace('t', '')
  input_str = input_str.replace(':', '')
  input_str = input_str.replace(' ', '')

  ; based on length, add in the extra info
  if (strlen(input_str) eq 4) then begin
    ; year supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '0101000000'
    endif else begin
      dt_str = input_str + '1231235959'
    endelse
  endif else if (strlen(input_str) eq 6) then begin
    ; year and month supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '01000000'
    endif else begin
      ; determine days for this month
      month_days = 31
      mm = fix(strmid(input_str, 4, 2))
      if (mm eq 4 or mm eq 6 or mm eq 9 or mm eq 11) then month_days = 30
      if (mm eq 2) then begin
        yy = fix(strmid(input_str, 0, 4))
        month_days = 28
        if (where(yy eq leap_years) ne -1) then month_days = 29 ; is leap year
      endif
      dt_str = input_str + string(month_days, format = '(i2.2)') + '235959'
    endelse
  endif else if (strlen(input_str) eq 8) then begin
    ; year, month, day supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '000000'
    endif else begin
      dt_str = input_str + '235959'
    endelse
  endif else if (strlen(input_str) eq 10) then begin
    ; year, month, day, hour supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '0000'
    endif else begin
      dt_str = input_str + '5959'
    endelse
  endif else if (strlen(input_str) eq 12) then begin
    ; year, month, day, hour, minute supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '00'
    endif else begin
      dt_str = input_str + '59'
    endelse
  endif else if (strlen(input_str) eq 14) then begin
    ; year, month, day, hour, minute, second supplied
    dt_str = input_str
  endif else begin
    print, 'Error: malformed datetime input string, string length unrecognized'
    return, ''
  endelse

  ; convert into ISO format string for API requests
  iso_str = strmid(dt_str, 0, 4) + '-' + strmid(dt_str, 4, 2) + '-' + strmid(dt_str, 6, 2) + 'T' + strmid(dt_str, 8, 2) + ':' + strmid(dt_str, 10, 2) + ':' + strmid(dt_str, 12, 2)

  ; return
  return, iso_str
end

function __aurorax_extract_request_id_from_response_headers, headers, url_add_length
  compile_opt hidden

  ; init
  request_id = ''

  ; find the location line and extract the request ID
  location_start_pos = strpos(headers, 'Location: ')
  if (location_start_pos eq -1) then begin
    __aurorax_message, 'Unable to extract request ID from response headers'
  endif else begin
    request_id = strmid(headers, location_start_pos + url_add_length, 36)
  endelse

  ; return
  return, request_id
end

function __aurorax_time2string, time
  compile_opt hidden

  ; seconds
  tempTime = double(time)
  result = strtrim(string(tempTime mod 60, format = '(f4.1, " seconds")'), 2)

  ; minutes
  tempTime = floor(tempTime / 60)
  if tempTime eq 0 then return, result
  unit = (tempTime mod 60) eq 1 ? ' minute, ' : ' minutes, '
  result = strtrim(string(tempTime mod 60, format = '(i2)') + unit + result, 2)

  ; return
  return, result
end

function __aurorax_ephemeris_convert_hash_location_nans, data
  ; locations with no data in them come back from the API as empty objects (ie. nbtrace={}), which
  ; are missing the lat and lon keys that are usually there. So to make the response more consistent,
  ; we overwrite these empty hashes with a hash of null values but with the anticipated keys
  for i = 0, n_elements(data['data']) - 1 do begin
    if (data['data', i].hasKey('nbtrace') eq 1) then begin
      if (n_elements(data['data', i, 'nbtrace']) eq 0) then data['data', i, 'nbtrace'] = hash('lat', !null, 'lon', !null)
    endif
    if (data['data', i].hasKey('sbtrace') eq 1) then begin
      if (n_elements(data['data', i, 'sbtrace']) eq 0) then data['data', i, 'sbtrace'] = hash('lat', !null, 'lon', !null)
    endif
    if (data['data', i].hasKey('location_geo') eq 1) then begin
      if (n_elements(data['data', i, 'location_geo']) eq 0) then data['data', i, 'location_geo'] = hash('lat', !null, 'lon', !null)
    endif
    if (data['data', i].hasKey('location_gsm') eq 1) then begin
      if (n_elements(data['data', i, 'location_gsm']) eq 0) then data['data', i, 'location_gsm'] = hash('lat', !null, 'lon', !null)
    endif
  endfor

  ; return
  return, data
end

function __aurorax_ephemeris_convert_struct_location_nans, data
  compile_opt hidden

  ; process ephemeris data
  converted_data = data.data ; this is used if there is no data
  if (n_elements(data.data) gt 0) then begin
    ; for each ephemeris record
    converted_data = list()
    for i = 0, n_elements(data.data) - 1 do begin
      ; build up new values
      e = data.data[i]
      location_geo_lat_new = e.location_geo.lat
      location_geo_lon_new = e.location_geo.lon
      location_gsm_lat_new = e.location_gsm.lat
      location_gsm_lon_new = e.location_gsm.lon
      nbtrace_lat_new = e.nbtrace.lat
      nbtrace_lon_new = e.nbtrace.lon
      sbtrace_lat_new = e.sbtrace.lat
      sbtrace_lon_new = e.sbtrace.lon
      if (isa(location_geo_lat_new, /string) eq 1) then location_geo_lat_new = !values.f_nan
      if (isa(location_geo_lon_new, /string) eq 1) then location_geo_lon_new = !values.f_nan
      if (isa(location_gsm_lat_new, /string) eq 1) then location_gsm_lat_new = !values.f_nan
      if (isa(location_gsm_lon_new, /string) eq 1) then location_gsm_lon_new = !values.f_nan
      if (isa(nbtrace_lat_new, /string) eq 1) then nbtrace_lat_new = !values.f_nan
      if (isa(nbtrace_lon_new, /string) eq 1) then nbtrace_lon_new = !values.f_nan
      if (isa(sbtrace_lat_new, /string) eq 1) then sbtrace_lat_new = !values.f_nan
      if (isa(sbtrace_lon_new, /string) eq 1) then sbtrace_lon_new = !values.f_nan

      ; create new struct
      geo_s = {lat: location_geo_lat_new, lon: location_geo_lon_new}
      gsm_s = {lat: location_gsm_lat_new, lon: location_gsm_lon_new}
      nb_s = {lat: nbtrace_lat_new, lon: nbtrace_lon_new}
      sb_s = {lat: sbtrace_lat_new, lon: sbtrace_lon_new}
      e_struct = {data_source: e.data_source, epoch: e.epoch, location_geo: geo_s, location_gsm: gsm_s, nbtrace: nb_s, sbtrace: sb_s, metadata: e.metadata}

      ; append
      converted_data.add, e_struct
    endfor
  endif

  ; create new struct
  converted_struct = {request_type: data.request_type, request_id: data.request_id, data: converted_data}

  ; return
  return, converted_struct
end

;+
; :Description:
;   Create conjunction search criteria block.
;
;   Supported keywords for /GROUND criteria blocks: programs, platforms, instrument_types, metadata_filters
;   Supported keywords for /SPACE criteria blocks: programs, platforms, hemispheres, metadata_filters
;   Supported keywords for /EVENTS criteria blocks: platforms, instrument_types, metadata_filters
;   Supported keywords for /CUSTOM criteria blocks: locations
;
; :Keywords:
;     programs: in, optional, List or Array
;         programs for this criteria block
;     platforms: in, optional, List or Array
;         platforms for this criteria block
;     instrument_types: in, optional, List or Array
;         instrument types for this criteria block
;     hemisphere: in, optional, List or Array
;         hemisphere values for this criteria block (valid values are 'northern' and/or 'southern')
;     locations: in, optional, List
;         list of 2-element arrays representing custom locations; order is [latitude, longitude].
;     metadata_filters: in, optional, Hash
;         metadata filters to filter for
;     ground: in, optional, Boolean
;         create a "ground" criteria block
;     space: in, optional, Boolean
;         create a "space" criteria block
;     events: in, optional, Boolean
;         create an "events" criteria block
;     custom: in, optional, Boolean
;         create a "custom locations" criteria block
;
; :Returns:
;     Struct
;
; :Examples:
;     cb = aurorax_create_criteria_block(programs = ['themis-asi'], /ground)
;     cb = aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space)
;     cb = aurorax_create_criteria_block(instrument_types = ['substorm onset'], /events)
;     cb = aurorax_create_criteria_block(locations = list([51.04, -114.07]), /custom)
;-
function aurorax_create_criteria_block, programs = programs, $
  platforms = platforms, $
  instrument_types = instrument_types, $
  hemisphere = hemisphere, $
  locations = locations, $
  metadata_filters = metadata_filters, $
  ground = ground_kw, $
  space = space_kw, $
  events = events_kw, $
  custom = custom_kw
  ; create the object
  if (keyword_set(ground_kw)) then begin
    ; ground criteria block
    obj = {programs: list(), platforms: list(), instrument_types: list(), ephemeris_metadata_filters: hash()}
    if (isa(programs) eq 1) then obj.programs = list(programs, /extract)
    if (isa(platforms) eq 1) then obj.platforms = list(platforms, /extract)
    if (isa(instrument_types) eq 1) then obj.instrument_types = list(instrument_types, /extract)
    if (isa(metadata_filters) eq 1) then obj.ephemeris_metadata_filters = hash(metadata_filters)
  endif else if (keyword_set(space_kw)) then begin
    ; space criteria block
    obj = {programs: list(), platforms: list(), instrument_types: list('footprint'), hemisphere: list(), ephemeris_metadata_filters: hash()}
    if (isa(programs) eq 1) then obj.programs = list(programs, /extract)
    if (isa(platforms) eq 1) then obj.platforms = list(platforms, /extract)
    if (isa(hemisphere) eq 1) then obj.hemisphere = list(hemisphere, /extract)
    if (isa(metadata_filters) eq 1) then obj.ephemeris_metadata_filters = hash(metadata_filters)
  endif else if (keyword_set(events_kw)) then begin
    ; events criteria block
    obj = {programs: list('events'), platforms: list(), instrument_types: list(), ephemeris_metadata_filters: hash()}
    if (isa(programs) eq 1) then obj.programs = list(programs, /extract)
    if (isa(platforms) eq 1) then obj.platforms = list(platforms, /extract)
    if (isa(instrument_types) eq 1) then obj.instrument_types = list(instrument_types, /extract)
    if (isa(metadata_filters) eq 1) then obj.ephemeris_metadata_filters = hash(metadata_filters)
  endif else if (keyword_set(custom_kw)) then begin
    ; custom locations criteria block
    obj = {locations: list()}
    if (isa(locations) eq 1) then begin
      compiled_location_hashes = list()
      for i = 0, n_elements(locations) - 1 do begin
        this_location_hash = {lat: locations[i, 0], lon: locations[i, 1]}
        compiled_location_hashes.add, this_location_hash
      endfor
      obj.locations = compiled_location_hashes
    endif
  endif else begin
    print, 'Error: no valid keyword used, unknown type of criteria block to create. Please use one of ' + $
      '/GROUND, /SPACE, /EVENTS, or /CUSTOM when calling this function.'
    return, !null
  endelse

  ; return
  return, obj
end

;+
; :Description:
;   Get a template response format for conjunction, ephemeris, or data product searches.
;
; :Keywords:
;     true: in, optional, Boolean
;         set all values in template as 'true'
;     false: in, optional, Boolean
;         set all values in template as 'false'
;     conjunctions: in, optional, Boolean
;         return the template for a conjunction search
;     ephemeris: in, optional, Boolean
;         return the template for an ephemeris search
;     data_products: in, optional, Boolean
;         return the template for a data products search
;
; :Returns:
;     Hash
;
; :Examples:
;   t = aurorax_create_response_format_template(/conjunctions)
;   t = aurorax_create_response_format_template(/ephemeris)
;   t = aurorax_create_response_format_template(/data_products)
;   t = aurorax_create_response_format_template(/conjunctions, /false)
;-
function aurorax_create_response_format_template, $
  true = true_kw, $
  false = false_kw, $
  conjunctions = conjunctions_kw, $
  ephemeris = ephemeris_kw, $
  data_products = data_products_kw
  ; set default value
  default = boolean(1)
  if (keyword_set(true_kw)) then default = boolean(1)
  if (keyword_set(false_kw)) then default = boolean(0)

  ; set template
  if (keyword_set(data_products_kw)) then begin
    template = { $
      start_ts: default, $
      end_ts: default, $
      data_source: { $
        identifier: default, $
        program: default, $
        platform: default, $
        instrument_type: default, $
        source_type: default, $
        display_name: default, $
        ephemeris_metadata_schema: { $
          field_name: default, $
          description: default, $
          data_type: default, $
          allowed_values: default, $
          additional_description: default}, $
        data_product_metadata_schema: { $
          field_name: default, $
          description: default, $
          data_type: default, $
          allowed_values: default, $
          additional_description: default}, $
        owner: default, $
        maintainers: default, $
        metadata: default}, $
      url: default, $
      data_product_type: default, $
      metadata: default}
  endif else if (keyword_set(ephemeris_kw)) then begin
    template = { $
      data_source: { $
        identifier: default, $
        program: default, $
        platform: default, $
        instrument_type: default, $
        source_type: default, $
        display_name: default, $
        ephemeris_metadata_schema: { $
          field_name: default, $
          description: default, $
          data_type: default, $
          allowed_values: default, $
          additional_description: default}, $
        data_product_metadata_schema: { $
          field_name: default, $
          description: default, $
          data_type: default, $
          allowed_values: default, $
          additional_description: default}, $
        owner: default, $
        maintainers: default, $
        metadata: default}, $
      epoch: default, $
      location_geo: {lat: default, lon: default}, $
      location_gsm: {lat: default, lon: default}, $
      nbtrace: {lat: default, lon: default}, $
      sbtrace: {lat: default, lon: default}, $
      metadata: default}
  endif else if (keyword_set(conjunctions_kw)) then begin
    template = { $
      conjunction_type: default, $
      start_ts: default, $
      end_ts: default, $
      min_distance: default, $
      max_distance: default, $
      closest_epoch: default, $
      farthest_epoch: default, $
      data_sources: { $
        identifier: default, $
        program: default, $
        platform: default, $
        instrument_type: default, $
        source_type: default, $
        display_name: default, $
        ephemeris_metadata_schema: { $
          field_name: default, $
          description: default, $
          data_type: default, $
          allowed_values: default, $
          additional_description: default}, $
        data_product_metadata_schema: { $
          field_name: default, $
          description: default, $
          data_type: default, $
          allowed_values: default, $
          additional_description: default}, $
        owner: default, $
        maintainers: default, $
        metadata: default}, $
      events: { $
        conjunction_type: default, $
        e1_source: { $
          identifier: default, $
          program: default, $
          platform: default, $
          instrument_type: default, $
          source_type: default, $
          display_name: default, $
          ephemeris_metadata_schema: { $
            field_name: default, $
            description: default, $
            data_type: default, $
            allowed_values: default, $
            additional_description: default}, $
          data_product_metadata_schema: { $
            field_name: default, $
            description: default, $
            data_type: default, $
            allowed_values: default, $
            additional_description: default}, $
          owner: default, $
          maintainers: default, $
          metadata: default}, $
        e2_source: { $
          identifier: default, $
          program: default, $
          platform: default, $
          instrument_type: default, $
          source_type: default, $
          display_name: default, $
          ephemeris_metadata_schema: { $
            field_name: default, $
            description: default, $
            data_type: default, $
            allowed_values: default, $
            additional_description: default}, $
          data_product_metadata_schema: { $
            field_name: default, $
            description: default, $
            data_type: default, $
            allowed_values: default, $
            additional_description: default}, $
          owner: default, $
          maintainers: default, $
          metadata: default}, $
        start_ts: default, $
        end_ts: default, $
        min_distance: default, $
        max_distance: default, $
        generated_e1_ephemeris_query: { $
          request_id: default, $
          data_sources: { $
            programs: default, $
            platforms: default, $
            instrument_types: default, $
            ephemeris_metadata_filters: { $
              logicalOperator: default, $
              expressions: { $
                key: default, $
                operator: default, $
                values: default}}}, $
          start_ts: default, $
          end_ts: default}, $
        generated_e2_ephemeris_query: { $
          request_id: default, $
          data_sources: { $
            programs: default, $
            platforms: default, $
            instrument_types: default, $
            ephemeris_metadata_filters: { $
              logicalOperator: default, $
              expressions: { $
                key: default, $
                operator: default, $
                values: default}}}, $
          start_ts: default, $
          end_ts: default}}}
  endif else begin
    print, '[aurorax_create_response_format_template] Error: Invalid usage. Calls to this function must have ' + $
      'one of /conjunctions, /ephemeris, or /data_products, and this call is missing one of these keywords.'
    template = !null
  endelse

  ; return
  return, template
end
