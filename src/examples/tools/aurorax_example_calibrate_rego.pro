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

pro aurorax_example_calibrate_rego
  ; ----------------
  ; Calibrating REGO 
  ; ----------------
  ; 
  ; When working with narrow band image data such as REGO and you'd like to convert the image to physical
  ; units (Rayleighs), there are various corrections and calibrations that need to be done. We as data
  ; providers, make available calibration files for each camera that help with this process. The
  ; calibrations are performed before the camera is deployed and after any major hardware repairs. For
  ; REGO, files can be found at the below data tree, or you can use the tooling to download them.
  ; 
  ;   https://data.phys.ucalgary.ca/sort_by_project/GO-Canada/REGO/calibration/
  ;   
  ; For a complete overview of how to determine which calibration files should be used, refer to the
  ; crib sheet:
  ;                 aurorax_ucalgary_example_calibrations.pro
  ;   
  ; There are three corrections and calibrations to do, where the order is important:
  ; 
  ;   1. Dark frame correction
  ;   2. Flatfield correction
  ;   3. Radiometric calibration
  ;

  ; First, download and read some of REGO data
  d = aurorax_ucalgary_download('REGO_RAW', '2021-11-04T03:25:00', '2021-11-04T03:35:00', site_uid = 'gill')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Download and read flatfield calibration files. We search for any calibration files
  ; in the years leading up to the date of interest and then use the most recent.
  ;
  ; When it comes to calibrations for narrow-band imagers, the device unique identifier is used to get
  ; the correct calibration and correction files. This number is a unique ID for the detector used at
  ; that site, and they can move around different sites over the years of operating the instruments
  ; (primarily driven by repairs to the detectors).
  ;
  ; The device UID is contained in the filenames and in the metadata.
  dataset_name = 'REGO_CALIBRATION_FLATFIELD_IDLSAV'
  start_search_ts = '2010-11-04T03:00:00'
  device_uid = '652'
  d = aurorax_ucalgary_download(dataset_name, start_search_ts, '2021-11-04T03:00:00', device_uid = device_uid)
  flatfield_cal = (aurorax_ucalgary_read(d.dataset, d.filenames))[-1].data[0]

  ; Repeat the above process for Rayleighs calibration
  dataset_name = 'REGO_CALIBRATION_RAYLEIGHS_IDLSAV'
  start_search_ts = '2010-11-04T03:00:00'
  device_uid = '652'
  d = aurorax_ucalgary_download(dataset_name, start_search_ts, '2021-11-04T03:00:00', device_uid = device_uid)
  rayleighs_cal = (aurorax_ucalgary_read(d.dataset, d.filenames))[-1].data[0]

  ; Calibrate the image data - note that dark frame is subtracted automatically unless /no_dark_subtract is passed
  images = image_data.data
  calibrated_images = aurorax_calibrate_rego(images, cal_flatfield = flatfield_cal, cal_rayleighs = rayleighs_cal)

  ; Plot before and after calibration
  raw_im = image(images[*, *, 100], title = 'Raw Image', location = [5, 5], rgb_table = 3, dimensions = [400, 400])
  cal_im = image(calibrated_images[*, *, 100], title = 'Calibrated Image (Rayleighs)', location = [517, 5], rgb_table = 3, dimensions = [400, 400])
end
