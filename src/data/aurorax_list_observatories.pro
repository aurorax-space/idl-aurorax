function aurorax_list_observatories,instrument_array,uid=uid
  ; set params
  param_str = '?instrument_array=' + instrument_array
  if (isa(uid) eq 1) then begin
    param_str += '&uid=' + uid
  endif

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.phys.ucalgary.ca'
  req->SetProperty,URL_PATH = 'api/v1/data_distribution/observatories' + param_str
  req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  status = json_parse(output,/TOSTRUCT)

  ; return
  return,status
end