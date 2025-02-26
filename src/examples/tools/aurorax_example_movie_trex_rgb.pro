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

pro aurorax_example_movie_trex_rgb
  ; First, download and read some TREx RGB data
  start_ts = '2021-11-04T03:30:00'
  end_ts = '2021-11-04T03:39:00'
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', start_ts, end_ts, site_uid = 'rabb')
  images = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Scale the image data array
  img_data = bytscl(images.data, min = 10, max = 120)
  loadct, 0, /silent

  ; Set up your writing directory
  ;
  ; NOTE: We will use the user's home directory for it here. Change as needed.
  home_dir = getenv('USERPROFILE') ; Windows
  if (home_dir eq '') then home_dir = getenv('HOME') ; Unix/Linux/macOS
  working_dir = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_movie_frames_example'

  ; Create an empty directory to store frames
  if not file_test(working_dir) then file_mkdir, working_dir

  ; Iterate through each frame, plot it, and save as png
  window, 0, xsize = 553, ysize = 480
  for i = 0, (size(img_data, /dimensions))[-1] - 1 do begin
    frame_fname = working_dir + path_sep() + 'frame' + string(i, format = '(I3.3)') + '.png'

    tv, img_data[*, *, *, i], /true
    write_png, frame_fname, tvrd(/true)
  endfor
  wdelete, 0

  ; Set the input and output filenames
  filenames = file_search(working_dir + path_sep() + '*')
  output_filename = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_example_movie.mp4'

  ; Now call the movie procedure by passing in the list of filenames
  movie_fps = 25
  aurorax_movie, filenames, output_filename, movie_fps
end
