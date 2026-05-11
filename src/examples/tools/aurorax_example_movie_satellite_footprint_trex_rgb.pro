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

pro aurorax_example_movie_satellite_footprint_trex_rgb
  ; --------------------------------------------------
  ; Creating a Movie with Satellite Footprints
  ; --------------------------------------------------
  ;
  ; This example generates a movie of TREx RGB ASI data taken at Gillam, MB (GILL) for 2026-03-09
  ; 03:24-03:30 UT, with the footprints of TRACERS-1, TRACERS-2, and REAL overlaid onto the images
  ; in CCD coordinates, using the skymap. The pattern extends to other satellites and
  ; ASI instruments.
  ;
  ; The general prodedure is as follows: search ephemeris, interpolate each platform's lat/lon to
  ; the ASI cadence, download & optionally scale the ASI data, load the skymap, then for every
  ; frame, project each visible satellite's location and recent trail onto CCD pixels via
  ; aurorax_ccd_contour() and overplot. Finally, combine the PNGs into an MP4 with aurorax_movie().
  ;

  ; Event constants
  start_ts = '2026-03-09T03:24:00'
  end_ts = '2026-03-09T03:30:00'

  site_uid = 'gill'
  dataset_name = 'TREX_RGB_RAW_NOMINAL'
  skymap_dataset = 'TREX_RGB_SKYMAP_IDLSAV'

  ; Assumed altitude for the emission. For TREx RGB, dominated by the 557.7 nm
  ; green-line emission, we use a typical height of 110 km.
  altitude_km = 110

  ; Display & interpolation settings
  intensity_min = 10
  intensity_max = 120
  trail_seconds = 30
  ephemeris_cadence_sec = 3
  movie_fps = 15

  ; Per-platform display color (RGB) & visibility window (only overlay while the
  ; footprint is actually within the FoV of the ASI, so labels appear and disappear
  ; as each satellite enters and leaves the field of view).
  platform_names = ['tracers1', 'tracers2', 'real']
  platform_rgb = [[0, 0, 255], [255, 0, 0], [255, 0, 255]]
  win_starts = ['2026-03-09T03:27:03', '2026-03-09T03:26:39', '2026-03-09T03:25:51']
  win_ends = ['2026-03-09T03:29:45', '2026-03-09T03:29:12', '2026-03-09T03:27:48']

  ; Search for the spacecraft footprints over the event window.
  programs = ['tracers', 'real']
  response = aurorax_ephemeris_search(start_ts, end_ts, programs = programs, $
  platforms = platform_names, instrument_types = 'footprint')
  ephemeris_data = response.data
  print, 'Got ', strtrim(string(n_elements(ephemeris_data)), 2), ' ephemeris records.'

  ; Split the ephemeris results by platform and linearly interpolate to the ASI cadence.
  ; The AuroraX ephemeris search returns footprints at a 1-minute cadence (from
  ; SSCWeb), so we interpolate up to the 3-second TREx RGB frame cadence here.
  ;
  ; sat_ephemeris is a hash keyed by platform name; each entry holds a struct that gives
  ; {.julday, .lats, .lons} at the target cadence.
  sat_ephemeris = hash()
  foreach pname, platform_names do begin
    p_jd = []
    p_lats = []
    p_lons = []
    for i = 0, n_elements(ephemeris_data) - 1 do begin
      if (ephemeris_data[i].data_source).platform ne pname then continue
      e = ephemeris_data[i].epoch
      jd = julday(long(strmid(e, 5, 2)), long(strmid(e, 8, 2)), long(strmid(e, 0, 4)), $
        long(strmid(e, 11, 2)), long(strmid(e, 14, 2)), long(strmid(e, 17, 2)))
      p_jd = [p_jd, jd]
      p_lats = [p_lats, (ephemeris_data[i].location_geo).lat]
      p_lons = [p_lons, (ephemeris_data[i].location_geo).lon]
    endfor
    if n_elements(p_jd) eq 0 then begin
      print, 'WARNING: no ephemeris records returned for ', pname
      continue
    endif

    ; Build the fine-cadence Julian-day grid spanning the original window.
    duration_sec = (p_jd[-1] - p_jd[0]) * 86400.0d
    n_steps = long(duration_sec / ephemeris_cadence_sec) + 1
    fine_jd = p_jd[0] + (dindgen(n_steps) * ephemeris_cadence_sec) / 86400.0d
    fine_lats = interpol(p_lats, p_jd, fine_jd)
    fine_lons = interpol(p_lons, p_jd, fine_jd)

    sat_ephemeris[pname] = {julday: fine_jd, lats: fine_lats, lons: fine_lons}
    print, pname, ': ', strtrim(string(n_elements(fine_jd)), 2), ' interpolated points'
  endforeach

  ; Download and scale the ASI data
  d = aurorax_ucalgary_download(dataset_name, start_ts, end_ts, site_uid = site_uid)
  images = aurorax_ucalgary_read(d.dataset, d.filenames)
  img_data = bytscl(images.data, min = intensity_min, max = intensity_max)
  loadct, 0, /silent

  ; Download the skymap. We need it to map satellite lat/lon to CCD pixels at the
  ; assumed emission altitude.
  d = aurorax_ucalgary_download_best_skymap(skymap_dataset, site_uid, start_ts)
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  skymap = skymap_data.data[0]

  ; Set up writing directory
  ;
  ; NOTE: We will use the user's home directory for it here. Change as needed.
  home_dir = getenv('USERPROFILE') ; Windows
  if (home_dir eq '') then home_dir = getenv('HOME') ; Unix/Linux/macOS
  working_dir = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_footprint_movie_frames_example'

  ; Create an empty directory to store frames
  if not file_test(working_dir) then file_mkdir, working_dir

  ; Convert trail length from seconds to samples on the interpolated ephemeris grid
  n_trail = round(trail_seconds / float(ephemeris_cadence_sec))

  ; Precompute visibility-window boundaries as Julian days.
  n_sats = n_elements(platform_names)
  win_starts_jd = dblarr(n_sats)
  win_ends_jd = dblarr(n_sats)
  for k = 0, n_sats - 1 do begin
    e = win_starts[k]
    win_starts_jd[k] = julday(long(strmid(e, 5, 2)), long(strmid(e, 8, 2)), long(strmid(e, 0, 4)), $
      long(strmid(e, 11, 2)), long(strmid(e, 14, 2)), long(strmid(e, 17, 2)))
    e = win_ends[k]
    win_ends_jd[k] = julday(long(strmid(e, 5, 2)), long(strmid(e, 8, 2)), long(strmid(e, 0, 4)), $
      long(strmid(e, 11, 2)), long(strmid(e, 14, 2)), long(strmid(e, 17, 2)))
  endfor

  ; Set up plotting (define a circular usersym to mark the satellite footprint location)
  device, decomposed = 1
  white = aurorax_get_decomposed_color([255, 255, 255])
  t = findgen(17) * (!pi * 2 / 16.0)
  usersym, cos(t), sin(t), /fill

  ; Iterate through each frame, draw it with overlays, and save as PNG
  window, 0, xsize = 553, ysize = 480
  n_frames = (size(img_data, /dimensions))[-1]
  for i = 0, n_frames - 1 do begin
    frame_ts = images.timestamp[i]
    frame_jd = julday(long(strmid(frame_ts, 5, 2)), long(strmid(frame_ts, 8, 2)), long(strmid(frame_ts, 0, 4)), $
      long(strmid(frame_ts, 11, 2)), long(strmid(frame_ts, 14, 2)), long(strmid(frame_ts, 17, 2)))

    ; Display the ASI frame
    tv, img_data[*, *, *, i], /true

    ; Overlay every satellite that is within its visibility window
    for k = 0, n_sats - 1 do begin
      pname = platform_names[k]
      if (frame_jd lt win_starts_jd[k]) or (frame_jd gt win_ends_jd[k]) then continue
      if not sat_ephemeris.haskey(pname) then continue
      
      ; Grab the relevant footprintlocations for this frame
      eph = sat_ephemeris[pname]
      !null = min(abs(eph.julday - frame_jd), i_now)
      i_tail_start = (i_now - n_trail + 1) > 0
      tail_lats = eph.lats[i_tail_start : i_now]
      tail_lons = eph.lons[i_tail_start : i_now]

      ; Project the satellite's geographic trail onto CCD pixels via the skymap.
      ccd_coords = aurorax_ccd_contour(skymap, contour_lats = tail_lats, contour_lons = tail_lons, $
        altitude_km = altitude_km)
      if n_elements(ccd_coords) le 1 then continue
      valid = where(finite(ccd_coords[*, 0]), n_valid)
      if n_valid eq 0 then continue
      ccd_x = ccd_coords[valid, 0]
      ccd_y = ccd_coords[valid, 1]

      ; Trail (thin line) + leading point (filled circle) + label
      sat_color = aurorax_get_decomposed_color(platform_rgb[*, k])
      plots, ccd_x, ccd_y, color = sat_color, /device, thick = 2
      plots, ccd_x[-1], ccd_y[-1], color = sat_color, /device, psym = 8, symsize = 1.5
      xyouts, ccd_x[-1] - 6, ccd_y[-1], strupcase(pname), color = sat_color, /device, $
        charsize = 1.2, alignment = 1.0
    endfor

    ; Add some text labels
    xyouts, 5, 460, 'TREx RGB', color = white, /device, charsize = 1.5
    xyouts, 5, 440, strupcase(site_uid), color = white, /device, charsize = 1.5
    xyouts, 5, 25, strmid(frame_ts, 0, 10), color = white, /device, charsize = 1.0
    xyouts, 5, 10, strmid(frame_ts, 11, 8) + ' UTC', color = white, /device, charsize = 1.0

    ; Save the frame
    frame_fname = working_dir + path_sep() + 'frame' + string(i, format = '(I3.3)') + '.png'
    write_png, frame_fname, tvrd(/true)
  endfor
  wdelete, 0

  ; Combine frames into a movie using aurorax_movie
  filenames = file_search(working_dir + path_sep() + '*')
  output_filename = home_dir + path_sep() + 'idlaurorax' + path_sep() + 'trex_rgb_footprint_movie_example.mp4'
  aurorax_movie, filenames, output_filename, movie_fps
end
