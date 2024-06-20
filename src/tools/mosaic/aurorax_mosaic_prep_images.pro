


function aurorax_mosaic_prep_images, image_list
    
    ; Verify that image_list is indeed a list, not array
    if (typename(image_list) ne "LIST") then stop, "(aurorax_mosaic_prep_images) Error: image_list must be a list, i.e. 'list(img_data_1, img_data_2, ...)'."
    
    ; Determine the number of expected frames
    ;
    ; NOTE: this is done to ensure that the eventual image arrays are all the
    ; same size, and we adequately account for dropped frames.
    ;
    ; Steps:
    ;   1) finding the over-arching start and end times of data across all sites
    ;   2) determine the cadence using the timestamps
    ;   3) determine the number of expected frames using the cadence, start and end
    start_ts = __get_julday(image_list[0].timestamp[0])
    end_ts = __get_julday(image_list[0].timestamp[-1])
    foreach site_data, image_list do begin
        this_start_ts = __get_julday(site_data.timestamp[0])
        this_end_ts = __get_julday(site_data.timestamp[-1])
        if (this_start_ts lt start_ts) then start_ts = this_start_ts
        if (this_end_ts gt end_ts) then end_ts = this_end_ts
    endforeach
    
    ; Determine cadance, and generate all expected timestamps
    cadence = __determine_cadence(image_list[0].timestamp)
    expected_juldays = timegen(start=start_ts, final=end_ts, step_size=cadence, units='S')
    if (end_ts - start_ts) gt 3 then stop, "(aurorax_mosaic_prep_images) Error: Excessive date range detected - Check that all data is from the same time range"
    expected_timestamps = string(expected_juldays, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, " ", CHI2.2, ":", CMI2.2, ":", CSI2.2))')
    expected_num_frames = n_elements(expected_timestamps)
    
    ; for each site
    site_uid_list = []
    images_dict = hash()
    dimensions_dict = hash()
    foreach site_image_data, image_list do begin

        site_data = site_image_data.data
        
        ; Add to site uid list
        if where(tag_names(site_image_data.metadata[0]) eq "SITE_UID", /null) ne !null then begin
            site_uid = site_image_data.metadata[0].site_uid
        endif else stop, "(aurorax_mosaic_prep_images) Error: Could not find SITE_UID when parsing metadata."
        
        ; Determine number of channels of image data
        if (size(site_data, /dimensions))[0] eq 3 then begin
            n_channels = 3
        endif else begin
            n_channels = 1
        endelse
        
        ; set image dimensions
        if n_channels eq 1 then begin
            height = (size(site_data, /dimensions))[1]
            width = (size(site_data, /dimensions))[0]
        endif else begin
            height = (size(site_data, /dimensions))[2]
            width = (size(site_data, /dimensions))[1]
        endelse
        dimensions_dict[site_uid] = [width, height]
        
        ; We don't attempt to handle the same site being passed in for multiple networks
        if where(site_uid eq images_dict.keys(), /null) ne !null then begin
            print, strupcase(site_uid), format="Same site between differing networks detected. Omitting additional %s data"
            continue
        endif
        
        site_uid_list = [site_uid_list, site_uid]
        
        ; initialize this site's image data variable
        site_images = reform(make_array(n_channels, width, height, expected_num_frames, /double, value=!values.f_nan))
        
        ; find the index in the data corresponding to each expected timestamp
        for i=0, n_elements(expected_timestamps)-1 do begin
            found_idx = where(((strsplit(site_image_data.timestamp, '.', /extract)).toarray())[*,0] eq expected_timestamps[i], /null)
            
            ; didn't find the timestamp, just move on because there will be no data for this timestamp
            if found_idx eq !null then continue
            
            ; Add data to array
            if n_channels eq 1 then begin
                 site_images[*,*,i] = site_data[*,*,found_idx]
            endif else begin
                site_images[*,*,*,i] = site_data[*,*,*,found_idx]
            endelse
        endfor
        
        ; insert this site's image data variable into image data hash
        images_dict[site_uid] = site_images
    endforeach

    ; cast into mosaic_data struct
    prepped_data = hash('site_uid',site_uid_list, 'timestamps',expected_timestamps, 'images',images_dict, 'images_dimensions',dimensions_dict)
    
    return, prepped_data
end


function __determine_cadence, timestamp_arr
    ;;;
    ;   Determines the cadence using a list of timestamps
    ;;;
    
    diff_seconds = []
    curr_ts = !null
    checked_timestamps = 0
    
    for i=0, n_elements(timestamp_arr)-1 do begin
        ; bail out if we've checked 10 timestamps, that'll be enough
        if (checked_timestamps gt 10) then break 
        
        if curr_ts eq !null then begin
            ; first iteration, initialize curr_ts variable
            curr_ts = timestamp_arr[i]
        endif else begin
            ; Calculate difference in seconds
            diff_sec = fix((strsplit((strsplit(timestamp_arr[i], ':', /extract))[-1], '.', /extract))[0]) - $
                       fix((strsplit((strsplit(curr_ts, ':', /extract))[-1], '.', /extract))[0])
            diff_seconds = [diff_seconds, diff_sec]
            curr_ts = timestamp_arr[i]
        endelse
        checked_timestamps += 1
        
    endfor
    
    ; Get hash of occurences of second differences
    sec_freq = hash()
    foreach elem, diff_seconds do begin
        sec_freq[elem] = 0
    endforeach
    foreach elem, diff_seconds do begin
        sec_freq[elem] += 1
    endforeach
    
    ; Set cadence to most common difference between timestamps
    cadence = !null
    max_occur = 0
    foreach sec, sec_freq.keys() do begin
        if sec_freq[sec] gt max_occur then begin
            max_occur = sec_freq[sec]
            cadence = sec
        endif
    endforeach
    
    if cadence eq !null then stop, "(aurorax_mosaic_prep_images) Error: Could not determine cadence of image data."
    
    return, cadence
    
end


function __get_julday, time_stamp
    ;;;
    ;   Splits a timestamp string into a struct with value of julian day
    ;   and string field to use for comparisons.
    ;   
    ;   Note: Expects timestamps of the form: 'yyyy-mm-dd HH:MM:SS.ff utc'
    ;;;
    
    if (not isa(time_stamp, /array)) then begin
        
        year = fix((strsplit(time_stamp, '-', /extract))[0])
        month = fix((strsplit(time_stamp, '-', /extract))[1])
        day = fix((strsplit(time_stamp, '-', /extract))[2])
        
        hour = fix((strsplit((strsplit(time_stamp, ' ', /extract))[1], ':', /extract))[0])
        minute = fix((strsplit((strsplit(time_stamp, ' ', /extract))[1], ':', /extract))[1])
        second = fix((strsplit((strsplit(time_stamp, ' ', /extract))[1], ':', /extract))[2])
        
        return, julday(month, day, year, hour, minute, second)
    endif else begin
        datetime_arr = []

        year = fix(((strsplit(time_stamp, '-', /extract)).toarray())[*,0])
        month = fix(((strsplit(time_stamp, '-', /extract)).toarray())[*,1])
        day = fix(((strsplit(time_stamp, '-', /extract)).toarray())[*,2])

        
        hour = fix(strmid((((strsplit(time_stamp, ':', /extract)).toarray())[*,0]), 1, 2, /reverse_offset))
        minute = fix((((strsplit(time_stamp, ':', /extract)).toarray())[*,1]))
        second = fix((((strsplit(time_stamp, ':', /extract)).toarray())[*,2]))
                
        return, julday(month, day, year, hour, minute, second)

    endelse
    
    
end
    
    





