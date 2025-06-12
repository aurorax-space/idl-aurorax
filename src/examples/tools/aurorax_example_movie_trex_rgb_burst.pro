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

pro aurorax_example_movie_trex_rgb_burst
  ; -----------------------------
  ; Creating TREx RGB Burst Movie
  ; -----------------------------
  ;
  ; There is a handy function available that makes a movie from any list of image
  ; files. This means that we need to generate the files first, and then pass the
  ; filenames into the function.
  ;
  ; Let's have a look at an example of making a movie for 5 minutes of TREx RGB data.
  ;

  ; Download 5 minute of TREx RGB Burst data. Burst data is extremely large.
  ; When working with burst data, it is best to load it in smaller chunks.
  ; The ability to read in burst data files will depend on your computer's
  ; resources, as large amounts of data will require more memory.
  ;
  ; For now, let's download 5 minutes of burst data. This is enough
  ; to make a fairly large movie due to the high cadence.
  d = aurorax_ucalgary_download('TREX_RGB_RAW_BURST', '2023-02-24T06:00:00', '2023-02-24T06:04:59', site_uid = 'rabb')
  images = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; Scale the image data array
  img_data = bytscl(images.data, min = 10, max = 120)
  loadct, 0, /silent

  ; Set up your writing directory
  ;
  ; NOTE: We will use the user's home directory for it here. Change as needed.
  home_dir = getenv('USERPROFILE') ; Windows
  if (home_dir eq '') then home_dir = getenv('HOME') ; Unix/Linux/macOS
  working_dir = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_burst_movie_frames_example'

  ; Create an empty directory to store frames
  if not file_test(working_dir) then file_mkdir, working_dir

  ; Iterate through each frame, plot it, and save as png
  window, 0, xsize = 553, ysize = 480
  for i = 0, (size(img_data, /dimensions))[-1] - 1 do begin
    frame_fname = working_dir + path_sep() + 'frame' + string(i, format = '(I3.3)') + '.png'
    
    ; Display the frame and optionally add labels or overplot on the frame
    tv, img_data[*, *, *, i], /true
    xyouts, 0.02, 0.02, 'TREx RGB - Burst Mode', /normal, color=aurorax_get_decomposed_color([255,255,255])
    
    write_png, frame_fname, tvrd(/true)
  endfor
  wdelete, 0

  ; Set the input and output filenames
  filenames = file_search(working_dir + path_sep() + '*')
  output_filename = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_burst_example_movie.mp4'

  ; Now call the movie procedure by passing in the list of filenames
  movie_fps = 25
  aurorax_movie, filenames, output_filename, movie_fps
end
