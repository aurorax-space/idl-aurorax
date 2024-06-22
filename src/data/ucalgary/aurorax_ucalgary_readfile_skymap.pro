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

function __aurorax_ucalgary_readfile_skymap,file_list,quiet_flag=quiet_flag
  ; init
  skymaps = list()

  ; read each file
  for i=0,n_elements(file_list)-1 do begin
    ; print
    if (quiet_flag eq 0) then begin
      print,'[aurorax_read] Reading file: ' + file_list[i]
    endif
    
    ; restore file
    restore,file_list[i]

    ; extract the version from the filename
    version_str = (((file_basename(file_list[i])).split('_'))[-1].split('\.'))[0]

    ; set object
    ;
    ; NOTE: we need to not name this 'skymap' because otherwise we'll
    ; collide with the just-restored 'skymap' variable.
    skymap_obj = {filename: file_list[i],$
      project_uid: skymap.project_uid,$
      site_uid: skymap.site_uid,$
      imager_uid: skymap.imager_uid,$
      site_map_latitude: skymap.site_map_latitude,$
      site_map_longitude: skymap.site_map_longitude,$
      site_map_altitude: skymap.site_map_altitude,$
      full_elevation: skymap.full_elevation,$
      full_azimuth: skymap.full_azimuth,$
      full_map_altitude: skymap.full_map_altitude,$
      full_map_latitude: skymap.full_map_latitude,$
      full_map_longitude: skymap.full_map_longitude,$
      generation_info: skymap.generation_info,$
      version: version_str}

    ; append to list
    skymaps.add,skymap_obj
  endfor

  ; return
  return,skymaps
end