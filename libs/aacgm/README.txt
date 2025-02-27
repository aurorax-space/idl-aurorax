How to cite:

Shepherd, S. G. (2014), Altitude-adjusted corrected geomagnetic coordinates:
Definition and functional approximations, J. Geophys. Res. Space Physics, 119,
7501–7521, doi:10.1002/2014JA020264.

AACGM-v2 Software
v2.7 20241122

CHECK OUTPUTS

IDL Instructions:

1. Download the coefficients and put them in a convenient directory

2. Set the environment variable AACGM_v2_DAT_PREFIX to the directory that
   you are storing the coefficients in AND include the prefix of the
   coefficient files, i.e., aacgm_coeffs-14-

   e.g.,

   AACGM_v2_DAT_PREFIX=/directory_you_put_coefficients_in/aacgm_coeffs-14-

   Note that if you used the old AACGM software from JHU/APL you should have
   a similar variable that is already set.

3. Untar the contents of the .tar file into a directory

4. Setup the magnetic field model by putting the GUFM1/IGRF coefficients file
   (magmodel_1590-2025.txt) somewhere or leaving them in the current directory
   and setting the environment variable IGRF_COEFFS to the fully qualified
   path, i.e.,

   IGRF_COEFFS=/directory_you_put_IGRF_coefs_in/magmodel_1590-2025.txt

5. Test software by running test.idl by typing:

   idl test.idl

   from the command line. The output should be self-explanatory. Any errors
   should be reported to simon.shepherd@dartmouth.edu.

   Looking at test.idl will give you an idea of how to use the software. The
   main function, cnvcoord_v2(), is intended to be a direct replacement
   for the equivalent function, cnvcoord(), but with more options. The
   following is a description of the function cnvcoord_v2() taken from
   aacgm_v2.pro:

; CALLING SEQUENCE:
;       pos = cnvcoord_v2(inpos,[inlong],[height], [/GEO], [/TRACE], [/BAD_IDEA)
;
;     Note on input arguments:
;      the routine can be called either with a 3-element floating
;      point array giving the input latitude, longitude and height
;      or it can be called with 3 separate floating point values
;      giving the same inputs.
;      The input array can also be given in the form inpos(3,d1,d2,...)
;
;     Keywords:
;       geo           - set this keyword to convert from AACGM to geographic
;                       coordinates. The default is from geographic to AACGM
;       trace         - perform the slower but more accurate field line tracing
;                       to determine the coordinate conversion at all
;                       altitudes.  This feature is new and still in beta form.
;       allow_trace   - perform field line tracing for altitudes above 2000 km.
;                       The default is to throw an error if the altitude is
;                       above 2000 km. Because the tracing requires geopack
;                       to be installed, it is not acceptable to just load
;                       the required geopack functions.
;       bad_idea      - field line tracing is forced above 2000 km unless this
;                       keyword is set, in which case the coefficients will be
;                       used to extrapolate above the maximum altitude that
;                       is intended. Note that results can be nonsensical when
;                       using this option and you are acknowledging it by
;                       setting this keyword.
;
;     Output:  
;       pos           - a vector of the same form as the input with
;                       latitude and longitude specified in degrees and
;                       the distance from the origin in Re

   To compute the magnetic local time (MLT) of a given point requires knowledge
   of the magnetic longitude and the time (UT). An example of computing MLT is:

   e = AACGM_v2_SetDateTime(yr,mo,dy,hr,mt,sc)  ; set time
   p = cnvcoord_v2(glat,glon,hgt) ; compute AACGM-v2 coordinates of point
   m = mlt_v2(p[1])               ; compute MLT of point using AACGM-v2 lon

   Note that AACGM-v2 longitude is much less sensitive to altitude; maximum
   difference of <1 degree (5 min in MLT) over the range 0-2000 km. For this
   reason there is no height passed directly into the MLT routine. The value
   of AACGM-v2 longitude does change with altitude and variations of MLT with
   altitude above a given geographic location do exist.


In order to use this software you must compile the following IDL libraries:

genmag.pro
igrflib_v2.pro
aacgmlib_v2.pro
aacgm_v2.pro
time.pro
astalg.pro
mlt_v2.pro

and the IGRF14 coefficients (igrf14coeffs.txt) must be identified by the
environment variable IGRF_COEFFS


This package include the following files:

AACGM IDL software:

README.txt            ; this file
release_notes.txt     ; details of changes to v2.7
aacgm_v2.pro          ; user functions
aacgmlib_v2.pro       ; internal library functions
genmag.pro            ; general purpose functions
igrflib_v2.pro        ; internal IGRF functions
time.pro              ; internal date/time functions
astalg.pro            ; astronomical algorithms
mlt_v2.pro            ; magnetic local time functions
igrf14coeffs.txt      ; IGRF14 coefficients (1900-2025)
magmodel_1590-2025.txt; magnetic field coefficients (1590-2025)
test.idl              ; idl driver script for testing
LICENSE-AstAlg.txt    ; license file for Astro algrorithms

