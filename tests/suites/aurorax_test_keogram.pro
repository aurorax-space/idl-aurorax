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
; Tests for keogram creation and NaN injection, using synthetic image
; arrays. No skymap and no real data are needed for any of this.

;+
; Build a run of 'yyyy-mm-dd HH:MM:SS utc' timestamps.
;-
function __atest_timestamps, n, cadence_sec, start_second = start_second
  compile_opt idl2

  if (n_elements(start_second) eq 0) then start_second = 0
  out = strarr(n)
  for i = 0, n - 1 do begin
    total_sec = start_second + i * cadence_sec
    hh = 6 + total_sec / 3600
    mm = (total_sec mod 3600) / 60
    ss = total_sec mod 60
    out[i] = '2021-01-01 ' + string(hh, format = '(i2.2)') + ':' + $
      string(mm, format = '(i2.2)') + ':' + string(ss, format = '(i2.2)') + ' utc'
  endfor
  return, out
end

pro aurorax_test_keogram
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'keogram create -- single channel'
  ; -----------------------------------------------------------
  ;
  ; 8 columns, 6 rows, 5 frames
  images = intarr(8, 6, 5)
  for f = 0, 4 do images[*, *, f] = f + 1
  timestamps = __atest_timestamps(5, 3)

  keo = aurorax_keogram_create(images, timestamps)
  atest_not_null, keo, 'a keogram is produced'
  atest_has_tag, keo, 'data', 'keogram has data'
  atest_has_tag, keo, 'ccd_y', 'keogram has ccd_y'
  atest_has_tag, keo, 'slice_idx', 'keogram has slice_idx'
  atest_has_tag, keo, 'timestamp', 'keogram has timestamp'
  atest_has_tag, keo, 'ut_decimal', 'keogram has ut_decimal'
  atest_has_tag, keo, 'axis', 'keogram has axis'
  atest_has_tag, keo, 'instrument_type', 'keogram has instrument_type'

  atest_equal, keo.instrument_type, 'asi', 'a plain image array is treated as ASI data'
  atest_equal, keo.axis, 0, 'the axis defaults to 0'
  atest_equal, keo.slice_idx, 4, 'axis 0 slices down the middle column (8/2)'

  dims = size(keo.data, /dimensions)
  atest_n_elements, dims, 2, 'single channel keogram data is two dimensional'
  atest_equal, dims[0], 5, 'the first data axis is frames'
  atest_equal, dims[1], 6, 'the second data axis is CCD rows'
  atest_n_elements, keo.ccd_y, 6, 'ccd_y spans the CCD rows'
  atest_n_elements, keo.timestamp, 5, 'all timestamps are carried through'

  ; each frame was filled with its own constant, so the keogram row for
  ; frame f must be entirely f+1
  atest_equal, keo.data[0, 0], 1, 'the first frame contributes its value'
  atest_equal, keo.data[4, 0], 5, 'the last frame contributes its value'
  atest_equal, keo.data[2, 3], 3, 'an interior sample comes from the right frame'

  ; -----------------------------------------------------------
  atest_suite, 'keogram create -- axis selection'
  ; -----------------------------------------------------------
  keo = aurorax_keogram_create(images, timestamps, axis = 1)
  atest_equal, keo.axis, 1, 'axis 1 is recorded'
  atest_equal, keo.slice_idx, 3, 'axis 1 slices down the middle row (6/2)'
  dims = size(keo.data, /dimensions)
  atest_equal, dims[0], 5, 'axis 1 still has frames on the first data axis'
  atest_equal, dims[1], 8, 'axis 1 spans the CCD columns'
  atest_n_elements, keo.ccd_y, 8, 'ccd_y spans the columns for axis 1'

  ; -----------------------------------------------------------
  atest_suite, 'keogram create -- UT decimal conversion'
  ; -----------------------------------------------------------
  ts = ['2021-01-01 06:00:00 utc', '2021-01-01 06:30:00 utc', '2021-01-01 12:15:30 utc']
  keo = aurorax_keogram_create(intarr(8, 6, 3), ts)
  atest_close, keo.ut_decimal[0], 6.0, 0.0001, 'midnight-relative hour converts exactly'
  atest_close, keo.ut_decimal[1], 6.5, 0.0001, 'thirty minutes past reads as .5'
  atest_close, keo.ut_decimal[2], 12.0 + 15.0 / 60.0 + 30.0 / 3600.0, 0.0001, $
    'minutes and seconds both contribute'

  ; -----------------------------------------------------------
  atest_suite, 'keogram create -- multi channel'
  ; -----------------------------------------------------------
  rgb = bytarr(3, 8, 6, 5)
  rgb[*] = 100b
  keo = aurorax_keogram_create(rgb, timestamps)
  atest_not_null, keo, 'an RGB keogram is produced'
  atest_equal, keo.slice_idx, 4, 'axis 0 on RGB slices the middle column'
  dims = size(keo.data, /dimensions)
  atest_n_elements, dims, 3, 'RGB keogram data is three dimensional'
  atest_equal, dims[0], 3, 'the channel axis comes first'
  atest_n_elements, keo.ccd_y, 6, 'ccd_y spans the CCD rows for RGB'

  ; -----------------------------------------------------------
  atest_suite, 'keogram create -- bad input'
  ; -----------------------------------------------------------
  atest_note, 'the next several calls print keogram validation errors -- that output is expected'
  atest_null, aurorax_keogram_create(5, timestamps), 'a scalar for images is rejected'
  atest_null, aurorax_keogram_create(images, timestamps, axis = 2), 'an axis other than 0 or 1 is rejected'
  atest_null, aurorax_keogram_create(intarr(8, 6), ['2021-01-01 06:00:00 utc']), $
    'a single 2D frame is rejected -- a keogram needs multiple frames'
  atest_null, aurorax_keogram_create(intarr(3, 8, 6), timestamps), $
    'a single RGB frame is rejected -- a keogram needs multiple frames'
  atest_null, aurorax_keogram_create(intarr(2, 3, 4, 5, 6), timestamps), $
    'a five dimensional array is rejected'

  ; -----------------------------------------------------------
  atest_suite, 'keogram inject nans -- no gaps'
  ; -----------------------------------------------------------
  atest_note, 'the next call prints a "no missing data" warning -- that output is expected'
  complete_ts = __atest_timestamps(10, 3)
  complete_images = intarr(8, 6, 10)
  for f = 0, 9 do complete_images[*, *, f] = f + 1
  keo = aurorax_keogram_create(complete_images, complete_ts)

  filled = aurorax_keogram_inject_nans(keo)
  atest_not_null, filled, 'a gapless keogram comes back rather than !null'
  atest_equal, (size(filled.data, /dimensions))[0], 10, 'a gapless keogram keeps its frame count'
  atest_equal, filled.data[0, 0], keo.data[0, 0], 'a gapless keogram is returned unchanged'

  ; -----------------------------------------------------------
  atest_suite, 'keogram inject nans -- with gaps'
  ; -----------------------------------------------------------
  ;
  ; ten frames at three second cadence with frames 3 and 4 missing, so the
  ; run covers 06:00:00 to 06:00:27 but only holds eight frames
  gapped_ts = [complete_ts[0 : 2], complete_ts[5 : 9]]
  gapped_images = intarr(8, 6, 8)
  for f = 0, 7 do gapped_images[*, *, f] = 50
  keo = aurorax_keogram_create(gapped_images, gapped_ts)
  atest_equal, (size(keo.data, /dimensions))[0], 8, 'the gapped keogram starts with eight frames'

  filled = aurorax_keogram_inject_nans(keo)
  atest_not_null, filled, 'a gapped keogram is filled rather than rejected'
  if (n_elements(filled) ne 0) then begin
    atest_equal, (size(filled.data, /dimensions))[0], 10, 'the filled keogram spans all ten slots'
    atest_n_elements, filled.timestamp, 10, 'the timestamp list is filled out to match'

    atest_false, finite(filled.data[3, 0]), 'the first missing frame is NaN'
    atest_false, finite(filled.data[4, 0]), 'the second missing frame is NaN'
    atest_true, finite(filled.data[0, 0]), 'a present frame before the gap is left alone'
    atest_true, finite(filled.data[5, 0]), 'a present frame after the gap is left alone'
    atest_equal, filled.data[0, 0], 50, 'present data keeps its value'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'keogram inject nans -- explicit fill value'
  ; -----------------------------------------------------------
  keo = aurorax_keogram_create(gapped_images, gapped_ts)
  filled = aurorax_keogram_inject_nans(keo, fill_val = 7)
  atest_not_null, filled, 'a custom fill value is accepted'
  if (n_elements(filled) ne 0) then begin
    atest_equal, (size(filled.data, /dimensions))[0], 10, 'the filled keogram still spans ten slots'
    atest_equal, filled.data[3, 0], 7, 'the gap carries the supplied fill value'
    atest_true, finite(filled.data[3, 0]), 'a numeric fill value stays finite'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'keogram inject nans -- rejections'
  ; -----------------------------------------------------------
  atest_note, 'the next few calls print inject_nans errors -- that output is expected'

  ; a cadence that disagrees with the data
  keo = aurorax_keogram_create(gapped_images, gapped_ts)
  atest_null, aurorax_keogram_inject_nans(keo, cadence = 10), $
    'a cadence that contradicts the timestamps is refused'

  ; a keogram spanning more than one day
  multiday_ts = ['2021-01-01 23:59:54 utc', '2021-01-01 23:59:57 utc', '2021-01-02 00:00:03 utc']
  keo = aurorax_keogram_create(intarr(8, 6, 3), multiday_ts)
  atest_null, aurorax_keogram_inject_nans(keo), 'a keogram spanning two days is refused'

  ; timestamps that are not in the expected format
  bad_ts = ['2021-01-01 060000 utc', '2021-01-01 060003 utc', '2021-01-01 060006 utc']
  keo = aurorax_keogram_create(intarr(8, 6, 3), bad_ts)
  atest_null, aurorax_keogram_inject_nans(keo), 'malformed timestamps are refused'
end
