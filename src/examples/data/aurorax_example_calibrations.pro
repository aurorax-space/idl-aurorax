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

pro aurorax_example_calibrations
  ; ------------
  ; Calibrations
  ; ------------
  ;
  ; Calibration data is used for converting data to physical units, i.e. converting to Rayleighs (usually
  ; from raw counts). This is relevant for several ASI arrays: REGO, TREx NIR, and TREx Blueline
  ;

  ; list all calibration datasets
  datasets = aurorax_list_datasets(name="CALIBRATION")
  print, "Calibration Datasets: "
  foreach d, datasets do begin
    if d.doi ne '!NULL' then begin
      print, '  '+d.name+' - '+d.doi
    endif else begin
      print, '  '+d.name+' (DOI coming soon...)'
    endelse
  endforeach
  print
  
  ; Typically, there are two calibration steps required in converting ASI data from
  ; raw counts to Rayleighs:
  ; 
  ;   1. Flatfield Correction
  ;   2. Rayleighs Calibration
  ;   
  ; IDL-AuroraX has dedicated routines for performing calibrations on each of the relevant imagers' data:
  ;   e.g. aurorax_calibrate_rego(), aurorax_calibrate_nir
  ; 
  ; Before using the above functions however, one must obtain the necessary calibration files to use
  ; as input to the calibration procedure
  ;   
  ; When selecting a calibration file to use for converting raw data to Rayleighs, we have to methods available:
  ;
  ;   1. Using the aurorax_ucalgary_download_best_calibration() function to choose automatically
  ;   2. Choosing calibration files manually
  ;
  ; Cameras are calibrated before they are deployed to the field, and after any in-house repairs are performed.
  ; There exist flatfield and Rayleighs calibration files for each specific camera detector. A detector can live
  ; at multiple sites thoughout the years of operating the instrument array. Hence, why they are not associated
  ; with a specific site, instead identified using the data device UID value. When using the raw data, this device
  ; UID is in the filename and metadata, helping to know which camera was operating at each site.
  ;

  ; 1. Automatically choosing calibration files
  ;
  ; The easiest way to choose a calibration is to lean on the aurorax_ucalgary_download_best_calibration()
  ; function to let IDL-AuroraX figure out what's best to use. It takes the dataset name, unique device
  ; dentifier, and a timestamp. 
  ;
  
  ; As an example, say we are interested in calibrating some REGO data that was taken from a REGO
  ; imager at RANK on 2021-11-04. A quick look at the data tree reveals that at this time, the 
  ; camera at this site was device 654, so we will use this in the IDL-AuroraX functions
  d_flatfield = aurorax_ucalgary_download_best_calibration('REGO_CALIBRATION_FLATFIELD_IDLSAV', '654', '2021-11-04T00:00:00')
  d_rayleighs = aurorax_ucalgary_download_best_calibration('REGO_CALIBRATION_RAYLEIGHS_IDLSAV', '654', '2021-11-04T00:00:00')
  
  ; Then we can read the two calibration files using IDL-AuroraX as we would for any other file
  flatfield_data = aurorax_ucalgary_read(d_flatfield.dataset, d_flatfield.filenames)
  print & print, 'Best flatfield calibration for RANK on 2021-11-04:'
  help, flatfield_data & print
  rayleighs_data = aurorax_ucalgary_read(d_rayleighs.dataset, d_rayleighs.filenames)
  print & print, 'Best Rayleighs calibration for RANK on 2021-11-04:'
  help, rayleighs_data & print
  
  ; 2. Choosing calibration files manually
  ;
  ; Since IDL-AuroraX reads data using filenames as parameters, we can utilize that to simply
  ; choose calibrations manually. You can download a range of calibration files (or all of them!)
  ; by expanding the timeframe to a `aurorax_ucalgary_download()` request. Then you
  ; can choose which filename to read in yourself.

  ; Let's download the calibration files for a few years around the date of interest
  start_dt = '2021-01-01T00:00:00'
  end_dt = '2023-01-01T00:00:00'
  d_flatfield = aurorax_ucalgary_download('REGO_CALIBRATION_FLATFIELD_IDLSAV', start_dt, end_dt, device_uid='654')
  d_rayleighs = aurorax_ucalgary_download('REGO_CALIBRATION_RAYLEIGHS_IDLSAV', start_dt, end_dt, device_uid='654')

  ; Let's look at the filenames to see what was downloaded
  print & print, 'All flatfield files downloaded:' & print, d_flatfield.filenames
  print & print, 'All Rayleighs files downloaded:' & print, d_rayleighs.filenames

  ; Upon inspecting the lists of filenames, we see that the first flatfield file (2021-08-06) and the
  ; second Rayleighs file are the files generated most recently *before* the date we are interested
  ; in looking at data for. Thus, we would decide that these are the correct calibrations to use, so
  ; let's read those one in.
  flatfield_data = aurorax_ucalgary_read(d_flatfield.dataset, d_flatfield.filenames[0]) ; first flatfield file
  rayleighs_data = aurorax_ucalgary_read(d_rayleighs.dataset, d_rayleighs.filenames[1]) ; second rayleighs file
  print & print, 'Manually determined best Flatfield calibration for Gillam on 2021-11-04:'
  help, flatfield_data & print
  print & print, 'Manually determined best Rayleighs calibration for Gillam on 2021-11-04:'
  help, rayleighs_data & print
end