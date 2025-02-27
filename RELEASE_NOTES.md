Version 1.4.0
-------------------------

- many updates to example procedures (additions, updates, added content/explanations)
- added `aurorax_get_dataset()` function
- preparations for adding support for TREx Spectrograph L1 data
- changes for parameters for `aurorax_list_observatories()` function
  - the `name` parameter is now required, and not a keyword. New name for the input is `instrument_array`.
  - addition of `uid` optional keyword
- added `aurorax_check_version()` function
- added `level` parameter to `aurorax_list_datasets()` function
- added support for performing conjunction searches with custom locations
- added the `aurorax_create_response_format_template()` function
- added support using a response format when performing conjunction, ephemeris, and data product searches
- added search description methods `aurorax_conjunction_describe()`, `aurorax_ephemeris_describe()`, and `aurorax_data_product_describe()`; example procedures updated to include them
- improvement to conjunction/ephemeris/data product searching to handle incorrect metadata filter expression operators


Version 1.3.1
-------------------------

- bugfix for plotting mosaics with a single site, while specifying a specific scaling min/max for that site


Version 1.3.0
-------------------------

- changed serialization of null values in ephemeris location data to be float NaN values instead of '!NULL' strings
    - applied to location_geo, location_gsm, nbtrace, sbtrace
    - not applied to metadata
- bugfix for ATM forward and inverse calculation functions for when an error occurs in the API
- added support for overplotting contours on CCD images
- added docstrings to ATM functions


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

