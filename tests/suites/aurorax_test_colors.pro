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
; Tests for aurorax_get_decomposed_color, which packs an RGB triple into the
; single long integer that IDL wants in decomposed colour mode.

pro aurorax_test_colors
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'decomposed colour -- channel packing'
  ; -----------------------------------------------------------
  ;
  ; the packing is R + G*256 + B*65536, so each primary isolates one byte
  atest_equal, aurorax_get_decomposed_color([0, 0, 0]), 0l, 'black is zero'
  atest_equal, aurorax_get_decomposed_color([1, 0, 0]), 1l, 'red occupies the low byte'
  atest_equal, aurorax_get_decomposed_color([0, 1, 0]), 256l, 'green occupies the middle byte'
  atest_equal, aurorax_get_decomposed_color([0, 0, 1]), 65536l, 'blue occupies the high byte'

  atest_equal, aurorax_get_decomposed_color([255, 0, 0]), 255l, 'full red'
  atest_equal, aurorax_get_decomposed_color([0, 255, 0]), 65280l, 'full green'
  atest_equal, aurorax_get_decomposed_color([0, 0, 255]), 16711680l, 'full blue'
  atest_equal, aurorax_get_decomposed_color([255, 255, 255]), 16777215l, 'white is the maximum value'

  ; -----------------------------------------------------------
  atest_suite, 'decomposed colour -- documented example'
  ; -----------------------------------------------------------
  atest_equal, aurorax_get_decomposed_color([0, 255, 255]), 16776960l, $
    'the cyan example from the docstring'

  ; -----------------------------------------------------------
  atest_suite, 'decomposed colour -- mixed values'
  ; -----------------------------------------------------------
  atest_equal, aurorax_get_decomposed_color([10, 20, 30]), 10l + 20l * 256l + 30l * 65536l, $
    'an arbitrary triple packs as R + G*256 + B*65536'
  atest_equal, aurorax_get_decomposed_color([128, 64, 32]), 2113664l, 'a mid grey-ish colour'

  ; the result must be a long, not an int -- the values overflow 16 bits
  result = aurorax_get_decomposed_color([255, 255, 255])
  atest_true, size(result, /type) eq 3 or size(result, /type) eq 14, $
    'the packed value is a long integer, so it does not overflow'

  ; -----------------------------------------------------------
  atest_suite, 'decomposed colour -- bad input'
  ; -----------------------------------------------------------
  atest_note, 'the next few calls print a "3-element array" error -- that output is expected'
  atest_null, aurorax_get_decomposed_color([1, 2]), 'a two element array is rejected'
  atest_null, aurorax_get_decomposed_color([1, 2, 3, 4]), 'a four element array is rejected'
  atest_null, aurorax_get_decomposed_color(5), 'a scalar is rejected'
end
