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
;       Download the best calibration file for the given dataset name, timestamp, and site UID.
;
; :Parameters:
;       dataset_name: in, required, String
;         name of the calibration dataset to download data for
;       device_uid: in, required, String
;         the device UID to evaluate.
;       time_stamp: in, required, String
;         timestamp, format as ISO time string (YYYY-MM-DDTHH:MM:SS)
;
; :Keywords:
;       download_path: in, optional, String
;         path to save data to, default is your home directory
;       overwrite: in, optional, Boolean
;         download the files regardless of them existing locally already
;       quiet: in, optional, Boolean
;         no print messages, data download will be silent
;
; :Returns:
;       Struct
;
; :Examples:
;       d = aurorax_ucalgary_download_best_calibration('REGO_CALIBRATION_FLATFIELD_IDLSAV', '654', '2021-11-04T00:00:00')
;       d = aurorax_ucalgary_download_best_calibration('TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV', '216', '2021-11-04T00:00:00', /overwrite)
;+
;-------------------------------------------------------------
function aurorax_ucalgary_download_best_calibration, $
  dataset_name, $
  device_uid, $
  time_stamp, $
  download_path = download_path, $
  overwrite = overwrite, $
  quiet = quiet
  ; set keyword flags
  overwrite_flag = 0
  quiet_flag = 0
  if keyword_set(overwrite) then overwrite_flag = 1
  if keyword_set(quiet) then quiet_flag = 1

  ; set working timestamp vars
  year = fix(strmid(time_stamp, 0, 4))
  month = fix(strmid(time_stamp, 5, 2))
  day = fix(strmid(time_stamp, 8, 2))
  hour = fix(strmid(time_stamp, 11, 2))
  minute = fix(strmid(time_stamp, 14, 2))
  second = fix(strmid(time_stamp, 17, 2))
  cdf_epoch, working_cdf, year, month, day, hour, minute, second, /compute

  ; get urls
  start_ts = '2000-01-01T00:00:00'
  end_ts = strmid(timestamp(/utc), 0, 19) ; current time in the format we want
  urls = aurorax_ucalgary_get_urls(dataset_name, start_ts, end_ts, device_uid = device_uid)

  ; for each calibration file
  latest_calibration_url = ''
  for i = 0, n_elements(urls.urls) - 1 do begin
    ; extract the start time
    this_start_str = ((((file_basename(urls.urls[i])).split('_'))[3]).split('-'))[0]
    year = fix(strmid(this_start_str, 0, 4))
    month = fix(strmid(this_start_str, 4, 2))
    day = fix(strmid(this_start_str, 6, 2))
    cdf_epoch, this_cdf, year, month, day, hour, minute, second, /compute

    ; check start time
    if (working_cdf ge this_cdf) then begin
      ; valid
      ;
      ; NOTE: this works because of the order that the list is in already
      latest_calibration_url = urls.urls[i]
    endif
  endfor

  ; check if we found any
  if (latest_calibration_url eq '') then begin
    print, 'Error: Unable to determine a calibration recommendation'
    return, !null
  endif

  ; set output root path (if it's not already defined)
  if (isa(download_path) ne 1) then begin
    download_path = __get_download_path()
  endif
  output_root_path = download_path + path_sep() + dataset_name

  ; download the url
  ; --------------------------
  ;
  ; set vars
  downloaded_files = list()
  total_bytes = 0
  url = latest_calibration_url
  filename_trimmed = url.remove(0, strlen(urls.dataset.data_tree_url))
  filename_trimmed = filename_trimmed.replace('/', path_sep())
  output_filename = output_root_path + path_sep() + filename_trimmed

  ; check if the file exists already
  if (overwrite_flag eq 0 and file_test(output_filename) eq 1) then begin
    if (quiet_flag eq 0) then print, '[aurorax_download] File already exists, not redownloading (' + output_filename + ')'
    downloaded_files.add, output_filename
  endif else begin
    ; make destination dir
    file_mkdir, file_dirname(output_filename)

    ; retrieve file
    req = obj_new('IDLnetUrl')
    req.setProperty, url_scheme = 'https'
    req.setProperty, url_port = 443
    req.setProperty, url_host = 'data.phys.ucalgary.ca'
    req.setProperty, url_path = url.replace('https://data.phys.ucalgary.ca/', '')
    req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

    ; if the url object throws an error it will be caught here
    catch, error_status
    if (error_status ne 0) then begin
      catch, /cancel
      req.getProperty, response_code = rspCode
      if (quiet_flag eq 0) then print, '[aurorax_download] URL download failed with error code ' + strtrim(string(rspCode), 2) + ': ' + url
      file_delete, output_filename ; don't want an empty 1kb file to stick around
      obj_destroy, req
      return, !null
    endif

    ; do request
    output = req.get(filename = output_filename)
    if (quiet_flag eq 0) then print, '[aurorax_download] Successfully downloaded ' + url

    ; get size of file
    total_bytes += __extract_content_length(req)

    ; add to list
    downloaded_files.add, output_filename

    ; cleaup
    obj_destroy, req
  endelse

  ; return
  return, {filenames: downloaded_files, count: n_elements(downloaded_files), dataset: urls.dataset, output_root_path: output_root_path, total_bytes: total_bytes}
end