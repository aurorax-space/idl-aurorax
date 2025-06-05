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

pro aurorax_example_skymaps
  ; -------
  ; Skymaps 
  ; -------
  ; 
  ; Skymap files are used for projecting all-sky image data on a map. Skymaps are 
  ; created for each of the ASI datasets we provide, and generate new ones every 
  ; year, or when the deployed instrument is serviced. 
  ; 
  ; A detailed description of the skymaps can be found at:
  ;     https://data.phys.ucalgary.ca/sort_by_project/other/documentation/skymap_file_description.pdf
  ; 
  ; If you find that you are projecting data onto a map with multiple imagers and an auroral arc is
  ; not lining up between two sites, this is normally resolved by using a different skymap (a good
  ; first try is the one before or after what you are using). If you continue to have issues, reach
  ; out to the dataset contact:
  ;     https://data.phys.ucalgary.ca/about_datasets
  ; 
  
  ; list all skymap datasets
  datasets = aurorax_list_datasets(name="SKYMAP")
  print, "Skymap Datasets: "
  foreach d, datasets do begin
    if d.doi ne '!NULL' then begin
      print, '  '+d.name+' - '+d.doi
    endif else begin
      print, '  '+d.name+' (DOI coming soon...)'
    endelse
  endforeach
  print
  
  ; When selecting a skymap to use for projecting an image onto a map, we have to methods available:
  ; 
  ;   1. Using the aurorax_ucalgary_download_best_skymap() function to choose automatically
  ;   2. Choosing a skymap manually
  ;
  ; Skymaps are generated for each site, and for a given time period. It is important to choose a 
  ; skymap that is valid for the date you're looking at data for, otherwise the image may not
  ; appear accurately when projected on a map.
  ; 
  
  ; 1. Automatically choosing a skymap
  ;
  ; The easiest way to choose a skymap is to lean on the aurorax_ucalgary_download_best_skymap()
  ; function to let IDL-AuroraX figure out what's best to use. It takes the dataset name,
  ; site/observatory unique identifier, and a timestamp. Since skymaps change over the course of
  ; an imaging season, it is important to supply the timestamp of the data that you are plotting.
  ; 
  ; To explore all available skymaps, you can see them in the data tree for each instrument array
  ;   e.g. https://data.phys.ucalgary.ca/sort_by_project/THEMIS/asi/skymaps/
  ;        https://data.phys.ucalgary.ca/sort_by_project/TREx/RGB/skymaps/
  
  ; For example, let's say we are working with data from the THEMIS ASI located at Gillam on
  ; 2021-11-04. We set these params and use IDL-AuroraX to download the best skymap:
  d = aurorax_ucalgary_download_best_skymap('REGO_SKYMAP_IDLSAV', 'gill', '2021-11-04T00:00:00')
  
  ; Then we can read the skymap using IDL-AuroraX as we would for any other file
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  print & print, 'Best skymap for Gillam on 2021-11-04:'
  help, skymap_data & print

  ; 2. Choosing a skymap manually
  ;
  ; Since IDL-AuroraX reads data using filenames as parameters, we can utilize that to simply
  ; choose a skymap manually. You can download a range of skymap files (or all of them!) by
  ; expanding the timeframe to a `aurorax_ucalgary_download()` request. Then you
  ; can choose which filename to read in yourself.
  
  ; Let's download the skymaps for a few years around the date of interest
  start_dt = '2021-01-01T00:00:00'
  end_dt = '2023-01-01T00:00:00'
  d = aurorax_ucalgary_download('REGO_SKYMAP_IDLSAV', start_dt, end_dt, site_uid='gill')
  
  ; Let's look at the filenames to see what was downloaded
  print & print, 'All skymaps downloaded:' & print, d.filenames
  
  ; Upon inspecting the list of filenames, we see that the first skymap (2021-01-08) is the one
  ; generated most recently *before* the date we are interested in looking at data for. Thus,
  ; we would decide that this is the correct skymap to use, so let's read that one in.
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames[0])
  print & print, 'Manually determined best skymap for Gillam on 2021-11-04:'
  help, skymap_data & print
end