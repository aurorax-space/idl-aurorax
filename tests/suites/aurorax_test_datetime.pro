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
; Tests for __aurorax_datetime_parser, the routine that turns the many
; shorthand timestamp formats the library accepts into the full ISO strings
; the AuroraX API expects.
;
; The expectations here are taken from the documented contract in the
; aurorax_conjunction_search docstring.

pro aurorax_test_datetime
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'datetime parser -- start timestamps'
  ; -----------------------------------------------------------
  ;
  ; every one of these is documented as meaning 2020-01-01T00:00:00
  expected = '2020-01-01T00:00:00'
  atest_equal, __aurorax_datetime_parser('2020', /interpret_as_start), expected, 'year only'
  atest_equal, __aurorax_datetime_parser('202001', /interpret_as_start), expected, 'year + month'
  atest_equal, __aurorax_datetime_parser('20200101', /interpret_as_start), expected, 'year + month + day'
  atest_equal, __aurorax_datetime_parser('2020010100', /interpret_as_start), expected, 'through hour'
  atest_equal, __aurorax_datetime_parser('202001010000', /interpret_as_start), expected, 'through minute'
  atest_equal, __aurorax_datetime_parser('2020-01-01', /interpret_as_start), expected, 'dash separated'
  atest_equal, __aurorax_datetime_parser('2020/01/01T00:00', /interpret_as_start), expected, 'slash separated with T'
  atest_equal, __aurorax_datetime_parser('2020-01-01 00:00', /interpret_as_start), expected, 'space separated'

  ; start is the default when neither keyword is given
  atest_equal, __aurorax_datetime_parser('2020'), expected, 'defaults to start interpretation'

  ; -----------------------------------------------------------
  atest_suite, 'datetime parser -- end timestamps'
  ; -----------------------------------------------------------
  ;
  ; every one of these is documented as meaning 2020-12-31T23:59:59
  expected = '2020-12-31T23:59:59'
  atest_equal, __aurorax_datetime_parser('2020', /interpret_as_end), expected, 'year only'
  atest_equal, __aurorax_datetime_parser('202012', /interpret_as_end), expected, 'year + month'
  atest_equal, __aurorax_datetime_parser('20201231', /interpret_as_end), expected, 'year + month + day'
  atest_equal, __aurorax_datetime_parser('2020123123', /interpret_as_end), expected, 'through hour'
  atest_equal, __aurorax_datetime_parser('202012312359', /interpret_as_end), expected, 'through minute'
  atest_equal, __aurorax_datetime_parser('2020-12-31', /interpret_as_end), expected, 'dash separated'
  atest_equal, __aurorax_datetime_parser('2020/12/31T23', /interpret_as_end), expected, 'slash separated with T'
  atest_equal, __aurorax_datetime_parser('2020-12-31 23', /interpret_as_end), expected, 'space separated'

  ; -----------------------------------------------------------
  atest_suite, 'datetime parser -- second-level precision'
  ; -----------------------------------------------------------
  ;
  ; seconds must survive intact -- sub-minute conjunction searching depends
  ; on the caller being able to specify them
  atest_equal, __aurorax_datetime_parser('2020-01-01T00:00:30', /interpret_as_start), $
    '2020-01-01T00:00:30', 'seconds preserved for a start timestamp'
  atest_equal, __aurorax_datetime_parser('20200101000030', /interpret_as_start), $
    '2020-01-01T00:00:30', 'seconds preserved, compact form'
  atest_equal, __aurorax_datetime_parser('2020-06-15T12:34:56', /interpret_as_end), $
    '2020-06-15T12:34:56', 'a fully specified end timestamp is passed through untouched'
  atest_equal, __aurorax_datetime_parser('2020-01-01t00:00:30', /interpret_as_start), $
    '2020-01-01T00:00:30', 'lowercase t separator accepted'

  ; -----------------------------------------------------------
  atest_suite, 'datetime parser -- month end dates'
  ; -----------------------------------------------------------
  atest_equal, __aurorax_datetime_parser('202001', /interpret_as_end), '2020-01-31T23:59:59', 'January -> 31 days'
  atest_equal, __aurorax_datetime_parser('202004', /interpret_as_end), '2020-04-30T23:59:59', 'April -> 30 days'
  atest_equal, __aurorax_datetime_parser('202006', /interpret_as_end), '2020-06-30T23:59:59', 'June -> 30 days'
  atest_equal, __aurorax_datetime_parser('202009', /interpret_as_end), '2020-09-30T23:59:59', 'September -> 30 days'
  atest_equal, __aurorax_datetime_parser('202011', /interpret_as_end), '2020-11-30T23:59:59', 'November -> 30 days'
  atest_equal, __aurorax_datetime_parser('202007', /interpret_as_end), '2020-07-31T23:59:59', 'July -> 31 days'

  ; February, leap and non-leap
  atest_equal, __aurorax_datetime_parser('202002', /interpret_as_end), '2020-02-29T23:59:59', 'February 2020 -> 29 days (leap)'
  atest_equal, __aurorax_datetime_parser('201902', /interpret_as_end), '2019-02-28T23:59:59', 'February 2019 -> 28 days'
  atest_equal, __aurorax_datetime_parser('201602', /interpret_as_end), '2016-02-29T23:59:59', 'February 2016 -> 29 days (leap)'
  atest_equal, __aurorax_datetime_parser('200002', /interpret_as_end), '2000-02-29T23:59:59', 'February 2000 -> 29 days (leap century)'

  ; KNOWN LIMITATION: leap years come from a hardcoded list spanning 1980-2040
  ; (aurorax_search_helpers.pro:55). February in a leap year outside that range
  ; is treated as 28 days. Pinned here so the behaviour is visible; if the list
  ; is ever replaced with a real calculation, this assertion should be updated
  ; to expect the 29th.
  atest_equal, __aurorax_datetime_parser('204402', /interpret_as_end), '2044-02-28T23:59:59', $
    'February 2044 -> 28 days (known limitation: outside the hardcoded leap year list)'

  ; -----------------------------------------------------------
  atest_suite, 'datetime parser -- input is not mutated'
  ; -----------------------------------------------------------
  ;
  ; Regression test. IDL passes by reference, and this routine strips
  ; separators from its input; it used to do so in place, which corrupted the
  ; caller's variable. Two calls with the same variable must agree.
  ts = '2020-01-01T00:00:00'
  first = __aurorax_datetime_parser(ts, /interpret_as_start)
  atest_equal, ts, '2020-01-01T00:00:00', 'caller variable is unchanged after the call'
  second = __aurorax_datetime_parser(ts, /interpret_as_start)
  atest_equal, second, first, 'a repeated call with the same variable gives the same answer'

  ; -----------------------------------------------------------
  atest_suite, 'datetime parser -- malformed input'
  ; -----------------------------------------------------------
  ;
  ; these return an empty string, and print their own complaint on the way out
  atest_note, 'the parser prints an error for each malformed input below -- that output is expected'
  atest_equal, __aurorax_datetime_parser('20201', /interpret_as_start), '', 'odd length (5) rejected'
  atest_equal, __aurorax_datetime_parser('2020010', /interpret_as_start), '', 'odd length (7) rejected'
  atest_equal, __aurorax_datetime_parser('', /interpret_as_start), '', 'empty string rejected'
  atest_equal, __aurorax_datetime_parser('2020010100003030', /interpret_as_start), '', 'too long (16) rejected'
end
