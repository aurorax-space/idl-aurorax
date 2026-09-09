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
;
; Tests for the small formatting and parsing helpers in
; aurorax_search_helpers.pro, plus the response format templates.

pro aurorax_test_search_helpers
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'humanize bytes'
  ; -----------------------------------------------------------
  atest_equal, __aurorax_humanize_bytes(long64(0)), '0 bytes', 'zero'
  atest_equal, __aurorax_humanize_bytes(long64(1)), '1 bytes', 'one byte'
  atest_equal, __aurorax_humanize_bytes(long64(512)), '512 bytes', 'under a kilobyte stays in bytes'
  atest_equal, __aurorax_humanize_bytes(long64(1023)), '1023 bytes', 'one below the kilobyte boundary'
  atest_equal, __aurorax_humanize_bytes(long64(1024)), '1.00 KB', 'exactly one kilobyte'
  atest_equal, __aurorax_humanize_bytes(long64(1536)), '1.50 KB', 'one and a half kilobytes'
  atest_equal, __aurorax_humanize_bytes(long64(1024) ^ 2), '1.00 MB', 'exactly one megabyte'
  atest_equal, __aurorax_humanize_bytes(long64(1024) ^ 3), '1.00 GB', 'exactly one gigabyte'
  atest_equal, __aurorax_humanize_bytes(long64(1024) ^ 3 * 2), '2.00 GB', 'two gigabytes'

  ; the boundaries are inclusive on the upper unit
  atest_contains, __aurorax_humanize_bytes(long64(1024) ^ 2 - 1), 'KB', 'one below a megabyte is still KB'
  atest_contains, __aurorax_humanize_bytes(long64(1024) ^ 3 - 1), 'MB', 'one below a gigabyte is still MB'

  ; -----------------------------------------------------------
  atest_suite, 'time to string'
  ; -----------------------------------------------------------
  atest_equal, __aurorax_time2string(0.0d), '0.0 seconds', 'zero seconds'
  atest_equal, __aurorax_time2string(5.5d), '5.5 seconds', 'a few seconds'
  atest_equal, __aurorax_time2string(59.9d), '59.9 seconds', 'just under a minute'
  atest_equal, __aurorax_time2string(60.0d), '1 minute, 0.0 seconds', 'exactly one minute is singular'
  atest_equal, __aurorax_time2string(65.0d), '1 minute, 5.0 seconds', 'one minute and change'
  atest_equal, __aurorax_time2string(125.5d), '2 minutes, 5.5 seconds', 'several minutes is plural'

  ; Regression test. There used to be no hours handling, and the minutes
  ; field is taken modulo 60, so an hour-long search reported itself as
  ; "0 minutes, 0.0 seconds" -- and an hour and five seconds was
  ; indistinguishable from sixty-five seconds.
  atest_equal, __aurorax_time2string(3600.0d), '1 hour, 0 minutes, 0.0 seconds', 'exactly one hour'
  atest_equal, __aurorax_time2string(3665.0d), '1 hour, 1 minute, 5.0 seconds', $
    'an hour and change is distinguishable from sixty-five seconds'
  atest_equal, __aurorax_time2string(7325.5d), '2 hours, 2 minutes, 5.5 seconds', $
    'several hours is plural'
  atest_equal, __aurorax_time2string(3660.0d), '1 hour, 1 minute, 0.0 seconds', $
    'a single minute past the hour stays singular'
  atest_not_equal, __aurorax_time2string(3665.0d), __aurorax_time2string(65.0d), $
    'an hour and five seconds no longer collides with sixty-five seconds'

  ; -----------------------------------------------------------
  atest_suite, 'request id extraction'
  ; -----------------------------------------------------------
  ;
  ; The caller passes an offset that covers 'Location: ' plus the URL prefix,
  ; leaving the 36 character UUID. For conjunctions that offset is 65.
  crlf = string(13b) + string(10b)
  request_id = '12345678-1234-1234-1234-123456789abc'
  headers = 'HTTP/1.1 202 Accepted' + crlf + $
    'Content-Type: application/json' + crlf + $
    'Location: https://api.aurorax.space/api/v1/conjunctions/requests/' + request_id + crlf

  extracted = __aurorax_extract_request_id_from_response_headers(headers, 65)
  atest_equal, extracted, request_id, 'the conjunctions offset of 65 lands on the request id'
  atest_equal, strlen(extracted), 36, 'the extracted id is a 36 character UUID'

  ; the ephemeris endpoint has a shorter path, hence a different offset
  eph_headers = 'HTTP/1.1 202 Accepted' + crlf + $
    'Location: https://api.aurorax.space/api/v1/ephemeris/requests/' + request_id + crlf
  atest_equal, __aurorax_extract_request_id_from_response_headers(eph_headers, 62), request_id, $
    'the ephemeris offset of 62 lands on the request id'

  ; no Location header at all
  atest_note, 'the next call prints an "unable to extract request ID" message -- that output is expected'
  no_location = 'HTTP/1.1 500 Internal Server Error' + crlf + 'Content-Type: text/html' + crlf
  atest_equal, __aurorax_extract_request_id_from_response_headers(no_location, 65), '', $
    'headers with no Location yield an empty request id'

  ; -----------------------------------------------------------
  atest_suite, 'response format template -- conjunctions'
  ; -----------------------------------------------------------
  t = aurorax_create_response_format_template(/conjunctions)
  atest_not_null, t, 'a conjunctions template is returned'
  atest_has_tag, t, 'conjunction_type', 'template has conjunction_type'
  atest_has_tag, t, 'start_ts', 'template has start_ts'
  atest_has_tag, t, 'end_ts', 'template has end_ts'
  atest_has_tag, t, 'min_distance', 'template has min_distance'
  atest_has_tag, t, 'max_distance', 'template has max_distance'
  atest_has_tag, t, 'closest_epoch', 'template has closest_epoch'
  atest_has_tag, t, 'farthest_epoch', 'template has farthest_epoch'
  atest_has_tag, t, 'data_sources', 'template has data_sources'
  atest_has_tag, t, 'events', 'template has events'
  atest_true, t.start_ts, 'values default to true'
  atest_true, t.events.e1_source.display_name, 'nested values default to true as well'

  t = aurorax_create_response_format_template(/conjunctions, /false)
  atest_false, t.start_ts, '/false flips the values off'
  atest_false, t.events.e1_source.display_name, '/false reaches the nested values too'

  t = aurorax_create_response_format_template(/conjunctions, /true)
  atest_true, t.start_ts, '/true is the same as the default'

  ; -----------------------------------------------------------
  atest_suite, 'response format template -- ephemeris and data products'
  ; -----------------------------------------------------------
  t = aurorax_create_response_format_template(/ephemeris)
  atest_not_null, t, 'an ephemeris template is returned'
  atest_has_tag, t, 'data_source', 'ephemeris template has data_source'
  atest_has_tag, t, 'epoch', 'ephemeris template has epoch'
  atest_has_tag, t, 'location_geo', 'ephemeris template has location_geo'
  atest_has_tag, t, 'location_gsm', 'ephemeris template has location_gsm'
  atest_has_tag, t, 'nbtrace', 'ephemeris template has nbtrace'
  atest_has_tag, t, 'sbtrace', 'ephemeris template has sbtrace'
  atest_true, t.location_geo.lat, 'ephemeris nested lat defaults to true'

  t = aurorax_create_response_format_template(/data_products)
  atest_not_null, t, 'a data products template is returned'
  atest_has_tag, t, 'start_ts', 'data products template has start_ts'
  atest_has_tag, t, 'end_ts', 'data products template has end_ts'
  atest_has_tag, t, 'url', 'data products template has url'
  atest_has_tag, t, 'data_product_type', 'data products template has data_product_type'
  atest_has_tag, t, 'data_source', 'data products template has data_source'

  ; -----------------------------------------------------------
  atest_suite, 'response format template -- no type keyword'
  ; -----------------------------------------------------------
  atest_note, 'the next call prints an "Invalid usage" error -- that output is expected'
  t = aurorax_create_response_format_template()
  atest_null, t, 'omitting the template type returns !null'
end
