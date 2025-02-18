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

function __aurorax_retrieve_availability, start_date, end_date, program, platform, instrument_type, source_type, url_path
  compile_opt idl2, hidden

  ; convert dates to ISO format
  start_iso_dt = __aurorax_datetime_parser(start_date, /interpret_as_start)
  end_iso_dt = __aurorax_datetime_parser(end_date, /interpret_as_end)
  if (start_iso_dt eq '' or end_iso_dt eq '') then return, []

  ; set params
  param_str = 'start=' + strmid(start_iso_dt, 0, 10)
  param_str += '&end=' + strmid(end_iso_dt, 0, 10)
  if (isa(program) eq 1) then begin
    param_str += '&program=' + program
  endif
  if (isa(platform) eq 1) then begin
    param_str += '&platform=' + platform
  endif
  if (isa(instrument_type) eq 1) then begin
    param_str += '&instrument_type=' + instrument_type
  endif
  if (isa(source_type) eq 1) then begin
    param_str += '&source_type=' + source_type
  endif

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = url_path
  req.setProperty, url_query = param_str
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req.get(/string_array)

  ; serialize into struct
  data = json_parse(output, /tostruct)

  ; cleanup
  obj_destroy, req

  ; return
  return, data
end

;+
; :Description:
;       Retrieve data availability information for ephemeris records
;       in the AuroraX Search Engine. Optional parameters are used to
;       filter unwanted data sources out.
;
;       This function returns the retrieved data availability information,
;       as a list of structs
;
; :Parameters:
;       start_date: in, required, String
;         start year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;       end_date: in, required, String
;         end year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;
; :Keywords:
;       program: in, optional, String
;         program to filter on
;       platform: in, optional, String
;         platform to filter on
;       instrument_type: in, optional, String
;         instrument type to filter on
;       source_type: in, optional, String
;         source type to filter on (valid values are: leo, heo, lunar, ground, event_list)

; :Returns:
;       List
;
; :Examples:
;       data = aurorax_ephemeris_availability('20200101','20200105',program='swarm')
;       data = aurorax_ephemeris_availability('2020-01-01','2020-03-15',program='themis',platform='themisc')
;+
function aurorax_ephemeris_availability, start_date, $
  end_date, program = program, $
  platform = platform, $
  instrument_type = instrument_type, $
  source_type = source_type
  compile_opt idl2

  ; retrieve availability and return
  data = __aurorax_retrieve_availability(start_date, end_date, program, platform, instrument_type, source_type, 'api/v1/availability/ephemeris')
  return, data
end

;+
; :Description:
;       Retrieve data availability information for data product records
;       in the AuroraX platform. Optional parameters are used to filter
;       unwanted data sources out.
;
;       This function returns the retrieved data availability information,
;       as a list of structs
;
; :Parameters:
;       start_date: in, required, String
;         start year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;       end_date: in, required, String
;         end year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;
; :Keywords:
;       program: in, optional, String
;         program to filter on
;       platform: in, optional, String
;         platform to filter on
;       instrument_type: in, optional, String
;         instrument type to filter on
;       source_type: in, optional, String
;         source type to filter on (valid values are: leo, heo, lunar, ground, event_list)
;
; :Returns:
;       List
;
; :Examples:
;       data = aurorax_data_products_availability('20200101','20200105',program='auroramax')
;       data = aurorax_data_products_availability('2020-01-01','2020-03-15',program='trex',platform='gillam')
;+
function aurorax_data_products_availability, start_date, $
  end_date, program = program, $
  platform = platform, $
  instrument_type = instrument_type, $
  source_type = source_type
  compile_opt idl2

  ; retrieve availability information and return
  data = __aurorax_retrieve_availability(start_date, end_date, program, platform, instrument_type, source_type, 'api/v1/availability/data_products')
  return, data
end
