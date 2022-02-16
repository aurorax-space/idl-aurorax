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

function __aurorax_retrieve_availability,start_yy,start_mm,start_dd,end_yy,end_mm,end_dd,program,platform,instrument_type,source_type,url_path
  ; set params
  param_str = 'start=' + string(start_yy, format='(i4.4)') + '-' + string(start_mm, format='(i2.2)') + '-' + string(start_dd, format='(i2.2)')
  param_str += '&end=' + string(end_yy, format='(i4.4)') + '-' + string(end_mm, format='(i2.2)') + '-' + string(end_dd, format='(i2.2)')
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
  OBJ_DESTROY,req

  ; return
  return,data
end


;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_AVAILABILITY_EPHEMERIS
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
;       aurorax_availability_ephemeris(start_yy, start_mm, start_dd, end_yy, end_mm, end_dd)
;
; PARAMETERS:
;       start_yy          start year to use, integer
;       start_mm          start month to use, integer
;       start_dd          start day to use, integer
;       end_yy            end year to use, integer
;       end_mm            end month to use, integer
;       end_dd            end day to use, integer
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
;       data = aurorax_availability_ephemeris(2020,1,1,2020,1,5,program='swarm')
;
; REVISION HISTORY:
;   - Initial implementation, Feb 2022, Darren Chaddock
;+
;-------------------------------------------------------------
function aurorax_availability_ephemeris,start_yy,start_mm,start_dd,end_yy,end_mm,end_dd,program=program,platform=platform,instrument_type=instrument_type,source_type=source_type
  data = __aurorax_retrieve_availability(start_yy,start_mm,start_dd,end_yy,end_mm,end_dd,program,platform,instrument_type,source_type,'api/v1/availability/ephemeris')
  return,data
end


;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_AVAILABILITY_DATA_PRODUCTS
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
;       aurorax_availability_data_products(start_yy, start_mm, start_dd, end_yy, end_mm, end_dd)
;
; PARAMETERS:
;       start_yy          start year to use, integer
;       start_mm          start month to use, integer
;       start_dd          start day to use, integer
;       end_yy            end year to use, integer
;       end_mm            end month to use, integer
;       end_dd            end day to use, integer
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
;       data = aurorax_availability_data_products(2020,1,1,2020,1,5,program='auroramax')
;
; REVISION HISTORY:
;   - Initial implementation, Feb 2022, Darren Chaddock
;+
;-------------------------------------------------------------
function aurorax_availability_data_products,start_yy,start_mm,start_dd,end_yy,end_mm,end_dd,program=program,platform=platform,instrument_type=instrument_type,source_type=source_type
  data = __aurorax_retrieve_availability(start_yy,start_mm,start_dd,end_yy,end_mm,end_dd,program,platform,instrument_type,source_type,'api/v1/availability/data_products')
  return,data
end
