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
  ; ---------------------
  ; Creating THEMIS Movie
  ; ---------------------
  ; 
  ; There is a handy function available that makes a movie from any list of image
  ; files. This means that we need to generate the files first, and then pass the
  ; filenames into the function.
  ; 
  ; Let's have a look at an example of making a movie for an hour of THEMIS data.
  ; 
  
  ; First, download and read some THEMIS data
  start_ts = '2021-11-04T09:20:00'
  end_ts = '2021-11-04T09:29:00'
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW', start_ts, end_ts, site_uid = 'fsmi')
  images = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Scale the image data array
  img_data = bytscl(images.data, min = 2000, max = 10000)
  loadct, 0, /silent

  ; Set up your writing directory
  ;
  ; NOTE: We will use the user's home directory for it here. Change as needed.
  home_dir = getenv('USERPROFILE') ; Windows
  if (home_dir eq '') then home_dir = getenv('HOME') ; Unix/Linux/macOS
  working_dir = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'themis_movie_frames_example'

  ; Create an empty directory to store frames
  if not file_test(working_dir) then file_mkdir, working_dir

  ; Iterate through each frame, plot it, and save as png
  window, 0, xsize = 256, ysize = 256
  for i = 0, (size(img_data, /dimensions))[-1] - 1 do begin
    frame_fname = working_dir + path_sep() + 'frame' + string(i, format = '(I3.3)') + '.png'

    tv, img_data[*, *, i]
    write_png, frame_fname, tvrd(/true)
  endfor
  wdelete, 0

  ; Set the input and output filenames
  filenames = file_search(working_dir + path_sep() + '*')
  output_filename = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'themis_example_movie.mp4'

  ; Now call the movie procedure by passing in the list of filenames
  movie_fps = 25
  aurorax_movie, filenames, output_filename, movie_fps
end
