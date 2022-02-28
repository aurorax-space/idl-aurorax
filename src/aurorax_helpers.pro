;-------------------------------------------------------------
; MIT License
;
; Copyright (c) 2022 University of Calgary
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;-------------------------------------------------------------

pro __aurorax_message,msg
  ; set datetime string
  dt_str = systime()

  ; print message
  print,'[' + dt_str + '] ' + msg
end

function __aurorax_humanize_bytes,bytes
  ; figure out which of bytes, kilobytes, megabytes, or gigabytes; and then convert it
  if (bytes ge long64(1024)^long64(3)) then begin
    bytes_converted = idlunit(strtrim(bytes,2) + ' bytes -> gigabytes')
    converted_str = strtrim(string(bytes_converted.quantity, format='(f6.2)') + ' GB', 2)
  endif else if (bytes ge long64(1024)^long64(2)) then begin
    bytes_converted = idlunit(strtrim(bytes,2) + ' bytes -> megabytes')
    converted_str = strtrim(string(bytes_converted.quantity, format='(f6.2)') + ' MB', 2)
  endif else if (bytes ge long64(1024)) then begin
    bytes_converted = idlunit(strtrim(bytes,2) + ' bytes -> kilobytes')
    converted_str = strtrim(string(bytes_converted.quantity, format='(f6.2)') + ' KB', 2)
  endif else begin
    converted_str = strtrim(bytes,2) + ' bytes'
  endelse

  ; return
  return,converted_str
end

function __aurorax_datetime_parser,input_str,INTERPRET_AS_START=start_kw,INTERPRET_AS_END=end_kw
  ; input of a datetime string of various formats, output is a full datetime
  ; string in the YYYY-MM-DDTHH:MM:SS format that will be used by the AuroraX
  ; API as part of requests
  dt_str = ''
  leap_years = [1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040]

  ; set flags
  start_flag = 1
  end_flag = 0
  if keyword_set(start_kw) then begin
    start_flag = 1
    end_flag = 0
  endif
  if keyword_set(end_kw) then begin
    start_flag = 0
    end_flag = 1
  endif

  ; remove some characters (-, /, T)
  input_str = input_str.replace('-','')
  input_str = input_str.replace('/','')
  input_str = input_str.replace('T','')
  input_str = input_str.replace('t','')
  input_str = input_str.replace(':','')
  input_str = input_str.replace(' ','')

  ; based on length, add in the extra info
  if (strlen(input_str) eq 4) then begin
    ; year supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '0101000000'
    endif else begin
      dt_str = input_str + '1231235959'
    endelse
  endif else if (strlen(input_str) eq 6) then begin
    ; year and month supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '01000000'
    endif else begin
      ; determine days for this month
      month_days = 31
      mm = fix(strmid(input_str,4,2))
      if (mm eq 4 or mm eq 6 or mm eq 9 or mm eq 11) then month_days = 30
      if (mm eq 2) then begin
        yy = fix(strmid(input_str,0,4))
        month_days = 28
        if (where(yy eq leap_years) ne -1) then month_days = 29  ; is leap year
      endif
      dt_str = input_str + string(month_days,format='(i2.2)') + '235959'
    endelse
  endif else if (strlen(input_str) eq 8) then begin
    ; year, month, day supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '000000'
    endif else begin
      dt_str = input_str + '235959'
    endelse
  endif else if (strlen(input_str) eq 10) then begin
    ; year, month, day, hour supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '0000'
    endif else begin
      dt_str = input_str + '5959'
    endelse
  endif else if (strlen(input_str) eq 12) then begin
    ; year, month, day, hour, minute supplied
    if (start_flag eq 1) then begin
      dt_str = input_str + '00'
    endif else begin
      dt_str = input_str + '59'
    endelse
  endif else if (strlen(input_str) eq 14) then begin
    ; year, month, day, hour, minute, second supplied
    dt_str = input_str
  endif else begin
    print,'Error: malformed datetime input string, string length unrecognized'
    return,''
  endelse

  ; convert into ISO format string for API requests
  iso_str = strmid(dt_str,0,4) + '-' + strmid(dt_str,4,2) + '-' + strmid(dt_str,6,2) + 'T' + strmid(dt_str,8,2) + ':' + strmid(dt_str,10,2) + ':' + strmid(dt_str,12,2)

  ; return
  return,iso_str
end

function __aurorax_extract_request_id_from_response_headers,headers,url_add_length
  ; init
  request_id = ''

  ; find the location line and extract the request ID
  location_start_pos = strpos(headers,'Location: ')
  if (location_start_pos eq -1) then begin
    __aurorax_message,'Unable to extract request ID from response headers'
  endif else begin
    request_id = strmid(headers,location_start_pos+url_add_length,36)
  endelse

  ; return
  return,request_id
end

function __aurorax_time2string,time
  ; seconds
  tempTime = double(time)
  if keyword_set(days) then tempTime *= 86400D
  result = strtrim(string(tempTime mod 60, format='(f4.1, " seconds")'),2)

  ; minutes
  tempTime = floor(tempTime / 60)
  if tempTime eq 0 then return, result
  unit = (tempTime mod 60) eq 1 ? ' minute, ' : ' minutes, '
  result = strtrim(string(tempTime mod 60, format='(i2)') + unit + result,2)

  ; return
  return, result
end

function aurorax_create_criteria_block,programs=programs,platforms=platforms,instrument_types=instrument_types,hemisphere=hemisphere,metadata_filters=metadata_filters,GROUND=ground_kw,SPACE=space_kw,EVENTS=events_kw
  ; create the object
  if (keyword_set(ground_kw) or keyword_set(events_kw)) then begin
    obj = {programs: list(), platforms: list(), instrument_types: list(), ephemeris_metadata_filters: hash()}
    if (isa(programs) eq 1) then obj.programs = list(programs,/extract)
    if (isa(platforms) eq 1) then obj.platforms = list(platforms,/extract)
    if (isa(instrument_types) eq 1) then obj.instrument_types = list(instrument_types,/extract)
    if (isa(metadata_filters) eq 1) then obj.ephemeris_metadata_filters = hash(metadata_filters)
  endif else if (keyword_set(space_kw)) then begin
    obj = {programs: list(), platforms: list(), instrument_types: list(), hemisphere: list(), ephemeris_metadata_filters: hash()}
    if (isa(programs) eq 1) then obj.programs = list(programs,/extract)
    if (isa(platforms) eq 1) then obj.platforms = list(platforms,/extract)
    if (isa(instrument_types) eq 1) then obj.instrument_types = list(instrument_types,/extract)
    if (isa(hemisphere) eq 1) then obj.hemisphere = list(hemisphere,/extract)
    if (isa(metadata_filters) eq 1) then obj.ephemeris_metadata_filters = hash(metadata_filters)
  endif else begin
    print,'Error: no keyword used, not sure what type of criteria block this should be. Please use one of /GROUND, /SPACE, or /EVENTS when calling this function'
    return,!NULL
  endelse

  ; return
  return,obj
end
