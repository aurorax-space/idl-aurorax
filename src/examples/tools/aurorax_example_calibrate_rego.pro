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
  ; First, download and read some of REGO data
  d = aurorax_ucalgary_download('REGO_RAW', '2021-11-04T03:25:00', '2021-11-04T03:35:00', site_uid = 'gill')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Download and read flatfield calibration files. We search for any calibration files
  ; in the years leading up to the date of interest and then use the most recent.
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
