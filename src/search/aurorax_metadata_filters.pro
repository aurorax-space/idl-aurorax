;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_CREATE_METADATA_FILTER_EXPRESSION
;
; PURPOSE:
;       Create metadata filter expression for searches
;
; EXPLANATION:
;       The AuroraX ephemeris, data products, and conjunction searches can take
;       metadata filters to help refine your search. This function provides
;       an easy way to create metadata filter expressions which will be added
;       to a metadata_filter object later on.
;
; CALLING SEQUENCE:
;       aurorax_create_metadata_filter_expression(key,values)
;
; PARAMETERS:
;       key           the metadata field key, string
;       values        the values to filter on, string or list
;
; KEYWORDS:
;       /OPERATOR_EQ          operator for this expression will be '='
;       /OPERATOR_NE          operator for this expression will be '!='
;       /OPERATOR_GT          operator for this expression will be '>'
;       /OPERATOR_LT          operator for this expression will be '<'
;       /OPERATOR_GE          operator for this expression will be '>='
;       /OPERATOR_LE          operator for this expression will be '<='
;       /OPERATOR_BETWEEN     operator for this expression will be 'between'
;       /OPERATOR_IN          operator for this expression will be 'in'
;       /OPERATOR_NOT_IN      operator for this expression will be 'not in'
;
; OUTPUT:
;       a metadata filter expression
;
; OUTPUT TYPE:
;       a hash
;
; EXAMPLES:
;       expression = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1',list('classified as APA'),/OPERATOR_IN)
;       expression = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence',95,/OPERATOR_GE)
;       expression = aurorax_create_metadata_filter_expression('tii_on','true',/OPERATOR_IN)
;       expression = aurorax_create_metadata_filter_expression('tii_quality_vixh','0,2',/OPERATOR_BETWEEN)
;+
;-------------------------------------------------------------
function aurorax_create_metadata_filter_expression,key,values,OPERATOR_EQ=eq_kw,OPERATOR_NE=ne_kw,OPERATOR_LT=lt_kw,OPERATOR_GT=gt_kw,OPERATOR_LE=le_kw,OPERATOR_GE=ge_kw,OPERATOR_BETWEEN=between_kw,OPERATOR_IN=in_kw,OPERATOR_NOT_IN=not_in_kw
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
    print,'Error: must supply one of the operator keywords, please add one and try again'
    return,hash()
  endif

  ; if the values is a number, convert it to a string
  if (isa(values,/number) eq 1) then begin
    values = strtrim(values,2)
  endif

  ; check to see if the values is not an array
  if (isa(values,/array) eq 0) then begin
    ; values is not an array, turn it into one
    values = list(values)
  endif

  ; create hash
  obj = hash('key', key, 'values', values, 'operator', operator)

  ; return
  return,obj
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_CREATE_METADATA_FILTER
;
; PURPOSE:
;       Create metadata filter object for searches
;
; EXPLANATION:
;       The AuroraX ephemeris, data products, and conjunction searches can take
;       metadata filters to help refine your search. This function provides
;       an easy way to create a metadata filter object using a list of expressions.
;
; CALLING SEQUENCE:
;       aurorax_create_metadata_filter(expressions)
;
; PARAMETERS:
;       expressions       the expressions to use for this metadata filter, list (use
;                         aurorax_create_metadata_filter_expressions() function to
;                         create the expression(s))
;
; OUTPUT:
;       the metadata filter
;
; OUTPUT TYPE:
;       a hash
;
; EXAMPLES:
;       expression1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', list('classified as APA'),/OPERATOR_IN)
;       expression2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95,/OPERATOR_GE)
;       expressions = list(expression1, expression2)
;       metadata_filters = aurorax_create_metadata_filter(expressions,/OPERATOR_AND)
;+
;-------------------------------------------------------------
function aurorax_create_metadata_filter,expressions,OPERATOR_AND=and_kw,OPERATOR_OR=or_kw
  ; initialize expressions
  if (isa(expressions) eq 0) then expressions = list()

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
  return,obj
end
