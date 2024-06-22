;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_SOURCES_LIST
;
; PURPOSE:
;       Retrieve AuroraX Search Engine data sources
;
; EXPLANATION:
;       Retrieve a list of data sources available in the AuroraX Search
;       Engine, with optional parameters used to filter for certain data
;       sources.
;
; CALLING SEQUENCE:
;       aurorax_sources_list()
;
; PARAMETERS:
;       program           program to filter on, string, optional
;       platform          platform to filter on, string, optional
;       instrument_type   instrument type to filter on, string, optional
;       source_type       source type to filter on (valid values are: leo, heo,
;                         lunar, ground, event_list), string, optional
;
; KEYWORDS:
;       /FORMAT_FULL_RECORD       data sources returned have all available information
;                                 about them
;       /FORMAT_IDENTIFIER_ONLY   data sources returned have minimal information about
;                                 them, just the identifier
;
; OUTPUT:
;       the found data sources
;
; OUTPUT TYPE:
;       a list of structs
;
; EXAMPLES:
;       data = aurorax_sources_list()
;       data = aurorax_sources_list(program='swarm',/FORMAT_FULL_RECORD)
;       data = aurorax_sources_list(platform='gillam')
;       data = aurorax_sources_list(program='trex', platform='fort smith')
;+
;-------------------------------------------------------------
function aurorax_sources_list,program=program,platform=platform,instrument_type=instrument_type,source_type=source_type,FORMAT_FULL_RECORD=format_full_record,FORMAT_IDENTIFIER_ONLY=format_identifier_only
  ; set format
  format = 'basic_info'
  if keyword_set(format_full_record) then format = 'full_record'
  if keyword_set(format_identifier_only) then format = 'identifier_only'

  ; set params
  param_str = 'format=' + format
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
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/data_sources'
  req->SetProperty,URL_QUERY = param_str
  req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  data = json_parse(output,/TOSTRUCT)

  ; remove under-the-hood adhoc data sources
  idxs_to_remove = list()
  for i=0,n_elements(data)-1 do begin
    if (data[i].identifier lt 0) then begin
      idxs_to_remove.add,i
    endif
  endfor
  remove,idxs_to_remove.toArray(),data

  ; cleanup
  obj_destroy,req

  ; return
  return,data
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_SOURCES_GET_STATS
;
; PURPOSE:
;       Retrieve AuroraX data source stats
;
; EXPLANATION:
;       Retrieve some additional information about a data source on the
;       AuroraX platform, such as the earliest and latest ephemeris
;       and data product records.
;
; CALLING SEQUENCE:
;       aurorax_sources_get_stats()
;
; PARAMETERS:
;       identifier        data source identifier, integer
;
; OUTPUT:
;       stats about the data source
;
; OUTPUT TYPE:
;       a struct
;
; EXAMPLES:
;       source = aurorax_sources_list(program='swarm', platform='swarma')
;       stats = aurorax_sources_get_stats(source[0].identifier)
;+
;-------------------------------------------------------------
function aurorax_sources_get_stats,identifier
  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/data_sources/' + strtrim(identifier,2) + '/stats'
  req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  data = json_parse(output,/TOSTRUCT)

  ; cleanup
  obj_destroy,req

  ; return
  return,data
end