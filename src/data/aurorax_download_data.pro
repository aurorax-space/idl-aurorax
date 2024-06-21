function __get_download_path
  ; check if the environment variable has been set
  download_path = getenv('AURORAX_ROOT_DATA_DIR')
  if not keyword_set(def_root) then begin
    ; env var not set, use home directory then
    download_path = (file_search('~',/expand_tilde))[0] + path_sep() + 'idlaurorax_data'
  endif
  return,download_path
end

function __extract_content_length,req
  ; init
  content_length = 0

  ; get response header
  req->GetProperty,response_header=response_header

  ; get the content length line
  longer_line = strcompress(strmid(response_header,strpos(strlowcase(response_header),'content-length')+strlen('content-length:'),15),/remove_all)
  content_length_str = ''
  for i=0,longer_line.strlen()-1 do begin
    this_char = longer_line.charat(i)
    if (strcmp(this_char, string([13B])) eq 0) then begin
      content_length_str += this_char
    endif else begin
      break
    endelse
  endfor

  ; convert to integer
  content_length = ulong(content_length_str)

  ; return
  return,content_length
end

function aurorax_download_data,dataset_name,start_ts,end_ts,site_uid=site_uid,device_uid=device_uid,download_path=download_path,overwrite=overwrite,quiet=quiet
  ; init
  time0 = systime(1)
  total_bytes = 0

  ; set keyword flags
  overwrite_flag = 0
  quiet_flag = 0
  if keyword_set(overwrite) then overwrite_flag = 1
  if keyword_set(quiet) then quiet_flag = 1

  ; set output root path (if it's not already defined)
  if (isa(download_path) ne 1) then begin
    download_path = __get_download_path()
  endif
  output_root_path = download_path + path_sep() + dataset_name

  ; get urls
  urls = aurorax_get_urls(dataset_name,start_ts,end_ts,site_uid=site_uid,device_uid=device_uid)

  ; download each file
  if (n_elements(urls.urls) eq 0) then begin
    if (quiet_flag eq 0) then print,'[aurorax_download] No files found to download'
    return,{filenames: list(), dataset: urls.dataset, output_root_path: output_root_path, total_bytes: 0}
  endif else begin
    downloaded_files = list()
    for i=0,n_elements(urls.urls)-1 do begin
      ; set vars
      url = urls.urls[i]
      filename_trimmed = url.remove(0, strlen(urls.dataset.data_tree_url))
      filename_trimmed = filename_trimmed.replace('/', path_sep())
      output_filename = output_root_path + path_sep() + filename_trimmed

      ; check if the file exists already
      if (overwrite_flag eq 0 and file_test(output_filename) eq 1) then begin
        if (quiet_flag eq 0) then print,'[aurorax_download] File already exists, not redownloading (' + output_filename + ')
        downloaded_files.Add,output_filename
        continue
      endif

      ; make destination dir
      file_mkdir,file_dirname(output_filename)

      ;      ; if the url object throws an error it will be caught here
      ;      catch,error_status
      ;      if (error_status ne 0) then begin
      ;        catch,/cancel
      ;        req->GetProperty,response_code=rspCode
      ;        if (quiet_flag eq 0) then print,'[aurorax_download] URL download failed with error code ' + strtrim(string(rspCode),2) + ': ' + url
      ;        file_delete,output_filename  ; don't want an empty 1kb file to stick around
      ;        obj_destroy,req
      ;        continue
      ;      endif

      ; retrieve file
      req = OBJ_NEW('IDLnetUrl')
      req->SetProperty,URL_SCHEME = 'https'
      req->SetProperty,URL_PORT = 443
      req->SetProperty,URL_HOST = 'data.phys.ucalgary.ca'
      req->SetProperty,URL_PATH = url.replace('https://data.phys.ucalgary.ca/', '')
      req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()
      output = req->Get(filename=output_filename)
      if (quiet_flag eq 0) then print,'[aurorax_download] Successfully downloaded ' + url

      ; get size of file
      total_bytes += __extract_content_length(req)

      ; add to list
      downloaded_files.Add,output_filename

      ; cleaup
      obj_destroy,req
    endfor
  endelse

  ; produce data rate line
  if (quiet_flag eq 0) then begin
    dtime = (systime(1) - time0)
    working_total_bytes = total_bytes
    i = 0
    while (working_total_bytes gt 1024L) do begin
      working_total_bytes = working_total_bytes / 1024.0
      i = i + 1
    endwhile
    prefix = (['','K','M','G','T'])[i]
    ;info_line = string(working_total_bytes,prefix,dtime,8*working_total_bytes/dtime,prefix,format='("Downloaded ",F6.1,X,A,"B in ",I," seconds: ",F7.1,X,A,"b/second")')
    ;print,'[aurorax_download] ' + info_line
    print,'[aurorax_download] Finished, downloaded ' + strcompress(fix(working_total_bytes),/remove_all) + ' ' + prefix + 'B in ' + strcompress(string(dtime,format='(d20.2)'),/remove_all) + " seconds"
  endif

  ; return
  return,{filenames: downloaded_files, dataset: urls.dataset, output_root_path: output_root_path, total_bytes: total_bytes}
end