Version 1.3.0
-------------------------

- changed serialization of null values in ephemeris location data to be float NaN values instead of '!NULL' strings
    - applied to location_geo, location_gsm, nbtrace, sbtrace
    - not applied to metadata
- bugfix for ATM forward and inverse calculation functions for when an error occurs in the API


Version 1.2.0
-------------------------

- added support for TREx ATM forward and inverse calculations
- bugfix for grid file metadata readings


Version 1.1.0
-------------------------

- added support for grid files
- bugfix to ephemeris search example


Version 1.0.0
-------------------------

- addition of data access, reading, and analysis support functions

