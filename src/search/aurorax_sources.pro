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

;+
; :Description:
;       Retrieve AuroraX Search Engine data sources, with optional parameters
;       used to filter for certain data sources. This function returns the found
;       data sources, as a list of structs.
;
; :Keywords:
;       program: in, optional, String
;           program to filter on
;       platform: in, optional, String
;           platform to filter on
;       instrument_type: in, optional, String
;           instrument type to filter on
;       source_type: in, optional, String
;           source type to filter on (valid values are: leo, heo, lunar, ground, event_list)
;       format_full_record: in, optional, Boolean
;           data sources returned have all available information about them
;       format_identifier_only: in, optional, Boolean
;           data sources returned have minimal information about them, just the identifier
;       include_stats: in, optional, Boolean
;           include stats information
;
; :Returns:
;       List
;
; :Examples:
;       ; simple example
;       data = aurorax_list_sources()
;
;       ; example with full record format
;       data = aurorax_list_sources(program='swarm', format_full_record=1)
;
;       ; example with platform filter
;       data = aurorax_list_sources(platform='gillam')
;
;       ; example with multiple filters
;       data = aurorax_list_sources(program='trex', platform='fort smith')
;
;       ; example with stats included
;       data = aurorax_list_sources(program='trex', include_stats=1)
;+
function aurorax_list_sources, $
  program = program, $
  platform = platform, $
  instrument_type = instrument_type, $
  source_type = source_type, $
  format_full_record = format_full_record, $
  format_identifier_only = format_identifier_only, $
  include_stats = include_stats
  compile_opt idl2

  ; set format
  format = 'basic_info'
  if keyword_set(format_full_record) then format = 'full_record'
  if keyword_set(format_identifier_only) then format = 'identifier_only'

  ; set stats flag
  include_stats_flag = 0
  if keyword_set(include_stats) then include_stats_flag = 1

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
  if (include_stats_flag eq 1) then begin
    param_str += '&include_stats=true'
  endif

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/data_sources'
  req.setProperty, url_query = param_str
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req.get(/string_array)

  ; serialize into struct
  data = json_parse(output, /tostruct)

  ; remove under-the-hood adhoc data sources
  pruned_data = list()
  for i = 0, n_elements(data) - 1 do begin
    if (data[i].identifier ge 0) then begin
      pruned_data.add, data[i]
    endif
  endfor

  ; cleanup
  obj_destroy, req

  ; return
  return, pruned_data
end
