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

function aurorax_get_decomposed_color, rgb_triple

  dims = size(rgb_triple, /dimensions)
  if dims ne [3] and dims ne [1,3] then stop, "Please enter color as a 3-element array, [R, G, B]."
  return, rgb_triple[0] + (rgb_triple[1] * 2L^8L) + (rgb_triple[2] * 2L^16L)

end