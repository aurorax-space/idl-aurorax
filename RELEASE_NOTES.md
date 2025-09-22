Version 1.7.1 (2025-09-22)
-------------------------
- bugfix for AACGM paths


Version 1.7.0 (2025-09-12)
-------------------------
- updates for ATM inversion routine
  - changed `characteristic_energy` output flag and data to `mean_energy`.
  - added `special_logic_keyword` parameter to help handle specific non-standard use cases on the backend ATM API.
  - removed `atmospheric_attenuation_correction` keyword


Version 1.6.0 (2025-07-07)
-------------------------
- added support for TREx ATM model version 2.0, enabled by default
  - This includes additional 'forward' parameters, and an expanded inversion region which now includes the area around Poker Flat.
- docstring updates


Version 1.5.0 (2025-06-23)
-------------------------
- changed initialization process (refer to README)
- added AACGM integration, including adding support for magentic coordinates in several functions (keograms, mosaics, contours, bounding box)
- added support for TREx Spectrograph data
- added support for SMILE ASI data
- added ability to create field-of-view (FoV) maps for any instrument network
- added support for TREx RGB 'burst' data, added crib sheet
- added `percentile` parameter to custom keogram function
- added `aurorax_keogram_inject_nans()` function to allow for dynamic handling of missing data, updated crib sheets to show usage
- added `aurorax_ucalgary_download_best_calibration()` function
- added support to reading functions to handle `start_dt` and `end_dt` parameters
- added support for the `first_record` keyword when reading ASI data in H5 format (TREx RGB nominal, SMILE ASI)
- updated all plotting functions to return graphics object if applicable
- improvement to grid file read function to optimize memory usage and increase performance
- bugfix for contour line orientation
- created several additional crib sheets, updated existing crib sheets
- code cleanup, docstring updates
- changed `aurorax_check_version()` function to return a struct instead of an integer
- updated `aurorax_ucalgary_get_urls()` function to include total bytes of returned URLs


Version 1.4.1 (2025-03-06)
-------------------------
- bugfix for ATM forward and inverse functions


Version 1.4.0 (2025-02-27)
-------------------------
- added support for performing conjunction searches with custom locations
- added the `aurorax_create_response_format_template()` function
- added support for using a response format when performing conjunction, ephemeris, and data product searches
- added search description methods `aurorax_conjunction_describe()`, `aurorax_ephemeris_describe()`, and `aurorax_data_product_describe()`
- added `aurorax_get_dataset()` function
- preparations for adding support for TREx Spectrograph L1 data
- added `aurorax_check_version()` function
- added `level` parameter to `aurorax_list_datasets()` function
- changed parameters for `aurorax_list_observatories()` function
  - the `name` parameter is now required, and not a keyword. New name for the input is `instrument_array`.
  - addition of `uid` optional keyword
- improvement to conjunction/ephemeris/data product searching to handle incorrect metadata filter expression operators
- many updates to example procedures (additions, updates, added content/explanations)


Version 1.3.1 (2024-11-21)
-------------------------
- bugfix for plotting mosaics with a single site, while specifying a specific scaling min/max for that site


Version 1.3.0 (2024-07-09)
-------------------------
- changed serialization of null values in ephemeris location data to be float NaN values instead of '!NULL' strings
    - applied to location_geo, location_gsm, nbtrace, sbtrace
    - not applied to metadata
- bugfix for ATM forward and inverse calculation functions for when an error occurs in the API
- added support for overplotting contours on CCD images
- added docstrings to ATM functions


Version 1.2.0 (2024-07-09)
-------------------------
- added support for TREx ATM forward and inverse calculations
- bugfix for grid file metadata readings


Version 1.1.0 (2024-07-09)
-------------------------
- added support for grid files
- bugfix to ephemeris search example


Version 1.0.0 (2024-06-20)
-------------------------
- addition of data access, reading, and analysis support functions

