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

pro aurorax_example_ephemeris_search
  ; perform search
<<<<<<< HEAD
  response = aurorax_ephemeris_search('2019-01-01T06:00', '2019-01-01T06:59', programs = ['swarm'], platforms = ['swarma'], instrument_types = ['footprint'])
=======
  print, '[Simple example] Starting search ...'
  response = aurorax_ephemeris_search( $
    '2019-01-01T00:00', $
    '2019-01-01T23:59', $
    programs = ['swarm'], $
    platforms = ['swarma'], $
    instrument_types = ['footprint'])
  print, '[Simple example] Found ' + string(n_elements(response.data), format = '(I0)') + ' ephemeris records'
  print, ''
>>>>>>> dev

  ; show output
  help, response
  print, ''

  help, response.data[0]
  print, ''
end

pro aurorax_example_ephemeris_search2
  ; get all ephemeris records in a day when Swarm A was in the north polar cap
  ;
  ; set search parameters
  start_ts = '2019-01-01T00:00'
  end_ts = '2019-01-01T23:59'
  programs = ['swarm']
  platforms = ['swarma']
  instrument_types = ['footprint']

  ; set metadata filter
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; perform search
  print, '[Simple metadata filters example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, $
    end_ts, $
    programs = programs, $
    platforms = platforms, $
    instrument_types = instrument_types, $
    metadata_filters = metadata_filters, $
    /quiet)
  print, '[Simple metadata filters example] Found ' + string(n_elements(r.data), format = '(I0)') + ' ephemeris records'
  print, ''
end

pro aurorax_example_ephemeris_search3
  ; set search parameters
  start_ts = '2019-01-01T00:00'
  end_ts = '2019-01-01T23:59'
  programs = ['swarm']
  platforms = ['swarma']
  instrument_types = ['footprint']

  ; describe it
  print, '[Describe example] Retrieving description ...'
  description = aurorax_ephemeris_describe(start_ts, end_ts, programs = programs, platforms = platforms, instrument_types = instrument_types)
  print, '[Describe example] Description: ' + description
  print, ''
end

pro aurorax_example_ephemeris_search4
  ; Do a simple ephemeris search for an hour of Swarm A data, with a specific response format. The response
  ; format will include the data source identifier, program, and platform. It will also include the geodetic
  ; location, the epoch, and any metadata.
  ;
  ; set our response format
  response_format = { $
    data_source: { $
      display_name: boolean(1), $
      identifier: boolean(1)}, $
    epoch: boolean(1), $
    nbtrace: { $
      lat: boolean(1), $
      lon: boolean(1)}, $
    sbtrace: { $
      lat: boolean(1), $
      lon: boolean(1)}, $
    metadata: boolean(1)}

  ; set core search parameters
  start_ts = '2019-01-01T00:00'
  end_ts = '2019-01-01T23:59'
  programs = ['swarm']
  platforms = ['swarma']
  instrument_types = ['footprint']

  ; perform search
  print, '[Response format example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, $
    end_ts, $
    programs = programs, $
    platforms = platforms, $
    instrument_types = instrument_types, $
    response_format = response_format, $
    /quiet)
  print, '[Response format example] Found ' + string(n_elements(r['data']), format = '(I0)') + ' ephemeris records'
  print, ''
end
