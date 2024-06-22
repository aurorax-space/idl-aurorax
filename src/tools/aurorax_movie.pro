pro aurorax_movie, input_filenames, output_filename, fps
    
    ; Read the first image supplied to determine video size
    tmp = read_image(input_filenames[0])
    
    ; Set movie dimensions based on first image
    if n_elements(size(tmp, /dimensions)) eq 1 then begin
        x_size = (size(tmp, /dimensions))[0]
        y_size = (size(tmp, /dimensions))[1]
    endif else if n_elements(size(tmp, /dimensions)) eq 3 then begin
        x_size = (size(tmp, /dimensions))[1]
        y_size = (size(tmp, /dimensions))[2]
    endif else begin
        print, "(aurorax_movie) Error: Unrecognized image type/shape."
        goto, error
    endelse

    ; If fully qualified path is provided, directorys must exist
    catch, error_status
    if error_status eq -1166 then begin
        print, "(aurorax_movie) Error: When providing fully qualified path," + $ 
               " directory tree must exist."
        goto, error
        catch, /cancel
    endif else if error_status ne 0 then catch, /cancel
    
    ; Initialize video object
    vid = idlffvideowrite(output_filename)
    vid_stream = vid.addvideostream(x_size, y_size, fps)
    
    ; Iterate through each image file
    foreach f, input_filenames do begin
        ; Read image, then add to video object
        frame = read_image(f)
        !Null = vid.put(vid_stream, frame)
        continue
    endforeach
    
    ; Close video and print user message.
    vid=0
    print, "Video succesfully created at '"+output_filename+"'."
    error:
end
