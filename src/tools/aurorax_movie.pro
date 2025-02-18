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

;+
; :Description:
;   Given a list of filenames referencing images, create and save a movie.
;
; :Arguments:
;   input_filenames: in, required, String
;     an array of strings giving filenames of all images
;   output_filename: in, required, String
;     the filename location at which to save the image
;   fps: in, required, String
;     integer giving the frames per second to create movie at
;
; :Examples:
;   aurorax_create_movie, file_search("path\to\images\*.png"), "movie.mp4", 30
;-
pro aurorax_movie, input_filenames, output_filename, fps
  compile_opt idl2

  ; Read the first image supplied to determine video size
  tmp = read_image(input_filenames[0])

  ; Set movie dimensions based on first image
  if n_elements(size(tmp, /dimensions)) eq 1 then begin
    x_size = (size(tmp, /dimensions))[0]
    y_size = (size(tmp, /dimensions))[1]
  endif else if n_elements(size(tmp, /dimensions)) eq 3 then begin
    x_size = (size(tmp, /dimensions))[1]
    y_size = (size(tmp, /dimensions))[2]
  endif else begin
    print, '[aurorax_movie] Error: Unrecognized image type/shape.'
    goto, error
  endelse

  ; If fully qualified path is provided, directorys must exist
  catch, error_status
  if error_status eq -1166 then begin
    print, '[aurorax_movie] Error: When providing fully qualified path,' + $
      ' directory tree must exist.'
    goto, error
    catch, /cancel
  endif else if error_status ne 0 then catch, /cancel

  ; Initialize video object
  vid = IDLffVideoWrite(output_filename)
  vid_stream = vid.addVideoStream(x_size, y_size, fps)

  ; Iterate through each image file
  foreach f, input_filenames do begin
    ; Read image, then add to video object
    frame = read_image(f)
    help, frame
    !null = vid.put(vid_stream, frame)
    continue
  endforeach

  ; Close video and print user message.
  vid = 0
  print, 'Video succesfully created at ''' + output_filename + '''.'
  error:
end
