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

function __aurorax_retrieve_availability,start_date,end_date,program,platform,instrument_type,source_type,url_path
  ; convert dates to ISO format
  start_iso_dt = __aurorax_datetime_parser(start_date,/interpret_as_start)
  end_iso_dt = __aurorax_datetime_parser(end_date,/interpret_as_end)
  if (start_iso_dt eq '' or end_iso_dt eq '') then return,[]

  ; set params
  param_str = 'start=' + strmid(start_iso_dt,0,10)
  param_str += '&end=' + strmid(end_iso_dt,0,10)
  if (isa(program) eq 1) then begin
    param_str += '&program=' + program
  endif
  if (isa(platform) eq 1) then begin
    param_str += '&platform=' + platform
  endif
  if (isa(instrument_type) eq 1) then begin
    param_str += '&instrument_type=' + instrument_type
  endif
  if (isa(source_type) eq 1) then begin
    param_str += '&source_type=' + source_type
  endif

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = url_path
  req->SetProperty,URL_QUERY = param_str

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  data = json_parse(output,/TOSTRUCT)

  ; cleanup
  obj_destroy,req

  ; return
  return,data
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_EPHEMERIS_AVAILABILITY
;
; PURPOSE:
;       Retrieve data availability information for ephemeris records
;
; EXPLANATION:
;       Retrieve data availability information for ephemeris records
;       in the AuroraX platform. Optional parameters are used to filter
;       unwanted data sources out.
;
; CALLING SEQUENCE:
;       aurorax_ephemeris_availability(start_date, end_date)
;
; PARAMETERS:
;       start_date        start year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;       end_date          end year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;       program           program to filter on, string, optional
;       platform          platform to filter on, string, optional
;       instrument_type   instrument type to filter on, string, optional
;       source_type       source type to filter on (valid values are: leo, heo,
;                         lunar, ground, event_list), string, optional
;
; OUTPUT
;       retrieved data availability information
;
; OUTPUT TYPE:
;       a list of structs
;
; EXAMPLES:
;       data = aurorax_ephemeris_availability('20200101','20200105',program='swarm')
;       data = aurorax_ephemeris_availability('2020-01-01','2020-03-15',program='themis',platform='themisc')
;
; REVISION HISTORY:
;   - Initial implementation, Feb 2022, Darren Chaddock
;+
;-------------------------------------------------------------
function aurorax_ephemeris_availability,start_date,end_date,program=program,platform=platform,instrument_type=instrument_type,source_type=source_type
  data = __aurorax_retrieve_availability(start_date,end_date,program,platform,instrument_type,source_type,'api/v1/availability/ephemeris')
  return,data
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_DATA_PRODUCTS_AVAILABILITY
;
; PURPOSE:
;       Retrieve data availability information for data product records
;
; EXPLANATION:
;       Retrieve data availability information for data product records
;       in the AuroraX platform. Optional parameters are used to filter
;       unwanted data sources out.
;
; CALLING SEQUENCE:
;       aurorax_data_products_availability(start_date, end_date)
;
; PARAMETERS:
;       start_date        start year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;       end_date          end year to use, string (YYYY, YYYYMM, or YYYYMMDD)
;       program           program to filter on, string, optional
;       platform          platform to filter on, string, optional
;       instrument_type   instrument type to filter on, string, optional
;       source_type       source type to filter on (valid values are: leo, heo,
;                         lunar, ground, event_list), string, optional
;
; OUTPUT
;       retrieved data availability information
;
; OUTPUT TYPE:
;       a list of structs
;
; EXAMPLES:
;       data = aurorax_data_products_availability('20200101','20200105',program='auroramax')
;       data = aurorax_data_products_availability('2020-01-01','2020-03-15',program='trex',platform='gillam')
;
; REVISION HISTORY:
;   - Initial implementation, Feb 2022, Darren Chaddock
;+
;-------------------------------------------------------------
function aurorax_data_products_availability,start_date,end_date,program=program,platform=platform,instrument_type=instrument_type,source_type=source_type
  data = __aurorax_retrieve_availability(start_date,end_date,program,platform,instrument_type,source_type,'api/v1/availability/data_products')
  return,data
end
