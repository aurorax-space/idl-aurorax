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
;       Create metadata filter expression for AuroraX Search Engine
;       queries.
;
;       The AuroraX Search Engine ephemeris, data products, and conjunction
;       searches can take metadata filters to help refine your search. This
;       function provides an easy way to create metadata filter expressions
;       which will be added to a metadata_filter object later on.
;
; :Parameters:
;       key: in, required, String
;         the metadata field key
;       values: in, required, String or List
;         the values to filter on
;
; :Keywords:
;       operator_eq: in, optional, Boolean
;         operator for this expression will be '='
;       operator_ne: in, optional, Boolean
;         operator for this expression will be '!='
;       operator_gt: in, optional, Boolean
;         operator for this expression will be '>'
;       operator_lt: in, optional, Boolean
;         operator for this expression will be '<'
;       operator_ge: in, optional, Boolean
;         operator for this expression will be '>='
;       operator_le: in, optional, Boolean
;         operator for this expression will be '<='
;       operator_between: in, optional, Boolean
;         operator for this expression will be 'between'
;       operator_in: in, optional, Boolean
;         operator for this expression will be 'in'
;       operator_not_in: in, optional, Boolean
;         operator for this expression will be 'not in'
;
; :Returns:
;       Hash
;
; :Examples:
;       expression = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1',list('classified as APA'),/OPERATOR_IN)
;       expression = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence',95,/OPERATOR_GE)
;       expression = aurorax_create_metadata_filter_expression('tii_on','true',/OPERATOR_IN)
;       expression = aurorax_create_metadata_filter_expression('tii_quality_vixh','0,2',/OPERATOR_BETWEEN)
;+
function aurorax_create_metadata_filter_expression, $
  key, $
  values, $
  operator_eq = eq_kw, $
  operator_ne = ne_kw, $
  operator_lt = lt_kw, $
  operator_gt = gt_kw, $
  operator_le = le_kw, $
  operator_ge = ge_kw, $
  operator_between = between_kw, $
  operator_in = in_kw, $
  operator_not_in = not_in_kw
    ; set operator
  operator = ''
  if keyword_set(eq_kw) then operator = '='
  if keyword_set(ne_kw) then operator = '!='
  if keyword_set(lt_kw) then operator = '<'
  if keyword_set(gt_kw) then operator = '>'
  if keyword_set(le_kw) then operator = '<='
  if keyword_set(ge_kw) then operator = '>='
  if keyword_set(between_kw) then operator = 'between'
  if keyword_set(in_kw) then operator = 'in'
  if keyword_set(not_in_kw) then operator = 'not in'
  if (operator eq '') then begin
    print, 'Error: must supply one of the operator keywords, please add one and try again'
    return, hash()
  endif

  ; if the values is a number, convert it to a string
  if (isa(values, /number) eq 1) then begin
    values = strtrim(values, 2)
  endif

  ; check to see if the values is not an array
  if (isa(values, /array) eq 0) then begin
    ; values is not an array, turn it into one
    values = list(values)
  endif

  ; create hash
  obj = hash('key', key, 'values', values, 'operator', operator)

  ; return
  return, obj
end

;+
; :Description:
;       Create metadata filter object for searches
;
;       The AuroraX ephemeris, data products, and conjunction searches can take
;       metadata filters to help refine your search. This function provides
;       an easy way to create a metadata filter object using a list of expressions.
;
; :Parameters:
;       expressions: in, required, List
;         the expressions to use for this metadata filter (use
;         aurorax_create_metadata_filter_expressions() function to
;         create the expression(s))
;
; :Keywords:
;       operator_and: in, optional, Boolean
;         logical operator for this filter will be 'AND'
;       operator_or: in, optional, Boolean
;         logical operator for this filter will be 'OR'
;
; :Returns:
;       Hash
;
; :Examples:
;       expression1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', list('classified as APA'),/OPERATOR_IN)
;       expression2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95,/OPERATOR_GE)
;       expressions = list(expression1, expression2)
;       metadata_filters = aurorax_create_metadata_filter(expressions,/OPERATOR_AND)
;+
function aurorax_create_metadata_filter, expressions, operator_and = and_kw, operator_or = or_kw
    
  ; set operator
  if keyword_set(and_kw) then begin
    operator = 'AND'
  endif else if keyword_set(or_kw) then begin
    operator = 'OR'
  endif else begin
    operator = 'AND'
  endelse

  ; create struct
  obj = {logical_operator: 'AND', expressions: expressions}

  ; return
  return, obj
end
