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
;       Plot individual spectra from a spectrograph data object.
;
; :Parameters:
;       spect_data: in, required, Struct
;         spectrograph data object to plot from, usually the return value of aurorax_ucalgary_read()
;       time_stamp: in, required, String
;         timestamp(s) for which spectral data will be plotted
;       spect_loc: in, required, Int
;         the bin number(s), corresponding to the spatial axis of the spectrograph data, to plot
;
; :Keywords:
;       title: in, optional, String
;         string giving the plot title
;       dimensions: in, optional, Array
;         two-element array giving dimensions of the plotting window in device coordinates
;       location: in, optional, Array
;         two-element array giving location of the plotting window in device coordinates
;       position: in, optional, Array
;         four-element array giving position [x0, y0, x1, y1] in normal coordinates (0.-1.)
;         of the plot within the window
;       color: in, optional, String
;         string(s) specifying an IDL color(s) to use for plotting spectra
;       thick: in, optional, Int
;         a scalar integer specifying the thickness of plotted spectra
;       xlabel: in, optional, String
;         string specifying the x-axis title
;       ylabel: in, optional, String
;         string specifying the y-axis title
;       ylim: in, optional, Float
;         a two element vector specifying the [min, max] intensities to plot for the y-axis
;       xlim: in, optional, Float
;         a two element vector specifying the [min, max] wavelengths (in nm) to plot for the x-axis
;       overplot: in, optional, Boolean
;         plots over the current function graphics plotting window (which must exist)
;       auto_legend: in, optional, Boolean
;         plots a legend with automatically determined labels
;       legend_position: in, optional, Float
;         the position, in normalized (0.0-1.0) coordinates, of the top right corner of the legend
;
; :Returns:
;       reference to the created graphic
;
; :Examples:
;       d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', '2021-02-16T09:00', '2021-02-16T09:59', site_uid = 'rabb')
;       spect_data = aurorax_ucalgary_read(d.dataset, d.filenames)
;       p = aurorax_spectra_plot, spect_data, "2021-02-16T09:30:00", 150
;+
function aurorax_spectra_plot, $
  spect_data, $
  time_stamp, $
  spect_loc, $
  title = title, $
  dimensions = dimensions, $
  location = location, $
  position = position, $
  color = color, $
  thick = thick, $
  ylog = ylog, $
  xlabel = xlabel, $
  ylabel = ylabel, $
  ylim = ylim, $
  xlim = xlim, $
  overplot = overplot, $
  auto_legend = auto_legend, $
  legend_position = legend_position
  ; Set default parameters if not passed
  if ~keyword_set(dimensions) then dimensions = [800, 400]
  if ~keyword_set(location) then location = [0, 0]
  if ~keyword_set(title) then title = ''
  if ~keyword_set(ylog) then ylog = 0
  if ~keyword_set(ylim) then ylim = [0, 10000]
  if ~keyword_set(xlabel) then xlabel = 'Wavelength (nm)'
  if ~keyword_set(ylabel) then ylabel = 'Intensity (R/nm)'
  if ~keyword_set(thick) then thick = 2
  if ~keyword_set(position) then position = [0.1, 0.15, 0.9, 0.9]
  if ~keyword_set(legend_position) then legend_position = [0.4, 0.85]

  ; Turn input plotting timestamp and spect loc into arrays if they're scalars
  if isa(time_stamp, /scalar) then time_stamp = [time_stamp]
  if isa(spect_loc, /scalar) then spect_loc = [spect_loc]

  ; check for input errors - spectra plotting
  total_n_plots = n_elements(time_stamp) * n_elements(spect_loc)
  if isa(color, /scalar) then color = [color]
  if keyword_set(color) and n_elements(color) ne total_n_plots then begin
    if total_n_plots gt n_elements(color) then begin
      print, '[aurorax_spectra_plot] Warning: not enough colors supplied for requested plot - remaining spectra will be plotted in black.'
      for i = 0, total_n_plots - 2 do begin
        if i ge n_elements(color) then continue
        color = [color, 'black']
      endfor
    endif
  endif

  if ~keyword_set(color) then begin
    color = []
    for i = 0, total_n_plots - 1 do begin
      plot_line_color = [plot_line_color, 'black']
    endfor
  endif

  ; Create plotting window
  if ~keyword_set(overplot) then !null = window(dimensions = dimensions, location = location)

  ; Pull out spectra, timestamps, wavelength from spect_data_objects
  spectra = spect_data.data.spectra
  ts = spect_data.timestamp
  wavelength = spect_data.metadata.wavelength

  if ~keyword_set(xlim) then xlim = [min(wavelength, /nan), max(wavelength, /nan)]

  ; Obtain indices along time dimension of spectra corresponding to requested timestamp(s)
  ts_idx_arr = []
  foreach t, time_stamp do begin
    ; search for ts in metadata array
    formatted_time_stamp = strjoin(strsplit(t, 'T', /regex, /extract), ' ') + ' UTC'
    idx = where(ts eq formatted_time_stamp, /null)

    ; raise error if timestamp doesn't exist in data
    if idx eq !null then begin
      print, '[aurorax_spectra_plot] Error: could not find data in spect_data for requested timestamp ' + t + '.'
      return, !null
    endif
    ts_idx_arr = [ts_idx_arr, idx]
  endforeach

  ; Plot the spectra
  plot_idx = 0
  plot_obj_arr = []
  foreach ts_idx, ts_idx_arr, k do begin
    foreach loc_idx, spect_loc do begin
      ; pull out spectrum for this time / location (bin)
      spectrum = reform(spectra[loc_idx, *, ts_idx])

      ; Dynamically create plot labels
      if n_elements(ts_idx_arr) gt 1 then begin
        if n_elements(spect_loc) gt 1 then begin
          plot_label = time_stamp[k] + '(bin ' + strcompress(string(loc_idx), /remove_all) + ')'
        endif else begin
          plot_label = time_stamp[k]
        endelse
      endif else if n_elements(spect_loc) gt 1 then begin
        plot_label = 'bin ' + strcompress(string(loc_idx), /remove_all)
      endif

      ; plot spectrum
      p = plot(wavelength, $
        spectrum, $
        color = color[plot_idx], $
        thick = thick, $
        ylog = ylog, $
        /overplot, $
        position = position, $
        name = plot_label)

      ; append graphic to array for legend creation
      plot_obj_arr = [plot_obj_arr, p]

      ; track how many we've plotted so we can cycle through colors
      plot_idx += 1
    endforeach
  endforeach

  ; create legend if requested
  if keyword_set(auto_legend) then !null = legend(target = plot_obj_arr, position = legend_position, /normal)

  ; set options once at the end so we're not overlapping axes
  p.xrange = xlim
  p.yrange = ylim
  p.xtitle = xlabel
  p.ytitle = ylabel
  p.title = title

  ; return value so user has control of plot object after creation
  return, p
end
