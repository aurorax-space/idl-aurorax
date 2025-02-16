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

pro aurorax_example_movie_themis
  compile_opt idl2

  ; First, download and read some THEMIS data
  start_ts = '2021-11-04T09:20:00'
  end_ts = '2021-11-04T09:29:00'
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW', start_ts, end_ts, site_uid = 'fsmi')
  images = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Scale the image data array
  img_data = bytscl(images.data, min = 2000, max = 10000)
  loadct, 0, /silent

  ; Set up your writing directory

  ; ===== **NOTE: Replace this when running** ======
  root_dir = 'C:\Users\USER_NAME\Downloads'
  ; ================================================

  writing_dir = root_dir + path_sep() + 'themis_movie_frames'

  ; Create an empty directory to store frames
  if not file_test(writing_dir) then file_mkdir, writing_dir

  ; Iterate through each frame, plot it, and save as png
  window, 0, xsize = 256, ysize = 256
  for i = 0, (size(img_data, /dimensions))[-1] - 1 do begin
    frame_fname = writing_dir + path_sep() + 'frame' + string(i, format = '(I3.3)') + '.png'

    tv, img_data[*, *, i]
    write_png, frame_fname, tvrd(/true)
  endfor
  wdelete, 0

  ; Now call the movie procedure by passing in the list of filenames
  filenames = file_search(writing_dir + path_sep() + '*')
  output_filename = root_dir + path_sep() + 'themis_movie.mp4'
  movie_fps = 50

  aurorax_movie, filenames, output_filename, movie_fps
end

pro testing_luck_mov
  compile_opt idl2

  f_list = file_search('\\bender.phys.ucalgary.ca\data\trex\rgb\stream0\2023\05\20\luck_rgb-03\ut06\20230520_06*_luck_rgb-03_full.h5')
  f_list = f_list[5 : 15]
  trex_imager_readfile, f_list, img, meta
  img = bytscl(img, min = 0, max = 80)

  for i = 0, n_elements(img[0, 0, 0, *]) - 1 do begin
    xyouts, 0.5, 0.025, meta[i].exposure_start_string, alignment = 0.5
    tv, img[*, *, *, i], /order, /true
    wait, 0.05
  endfor
end
