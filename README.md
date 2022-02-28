<a href="https://aurorax.space/"><img alt="AuroraX" src="logo.svg" height="60"></a>

![Stable version](https://img.shields.io/badge/Latest%20stable%20release-v0.1.1-orange)
![IDL version required](https://img.shields.io/badge/IDL-8.7.1%2B-blue)
[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://github.com/aurorax-space/idl-aurorax/blob/main/LICENSE)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6098075.svg)](https://doi.org/10.5281/zenodo.6098075)

IDL-AuroraX is an IDL library for interacting with [AuroraX](https://aurorax.space), a project working to be the world's first and foremost data platform for auroral science. The primary objective of AuroraX is to enable mining and exploration of existing and future auroral data, enabling key science and enhancing the benefits of the world's investment in auroral instrumentation. This will be accomplished with the development of key systems/standards for uniform metadata generation and search, image content analysis, interfaces to leading international tools, and a community involvement that includes more than 80% of the world's data providers.

IDL-AuroraX officially supports IDL 8.7.1+ (limited testing on older versions).

Some links to help:
- [AuroraX main website](https://aurorax.space)
- [IDL-AuroraX documentation](https://docs.aurorax.space/code/overview)

## Limitations

Please note, this IDL library only provides the ability to **retrieve** data from the AuroraX platform. It does not have functions for uploading or editing data on AuroraX. Please use the Python library, [PyAuroraX](https://github.com/aurorax-space/pyaurorax) for this functionality.

## Installation

Installation can be done two different ways: 1) using the `ipm` command, or 2) manually adding the files to your IDL path.

You can view all previous versions by browsing the AuroraX data tree [here](https://data.aurorax.space/data/software/idl-aurorax).

### Using ipm

Since IDL 8.7.1, there exists an IDL package manager called [ipm](https://www.l3harrisgeospatial.com/docs/ipm.html#INSTALL). We can use this to install the idl-aurorax library with a single command.

From the IDL command prompt, run the following:

```idl
IDL> ipm,/install,'https://data.aurorax.space/data/software/idl-aurorax/latest.zip'
```

Then, add the following to your startup file, or run the commands manually using the IDL command prompt:

```idl
.run aurorax_helpers
.run aurorax_requests
.run aurorax_metadata_filters
.run aurorax_availability
.run aurorax_conjunctions
.run aurorax_data_products
.run aurorax_ephemeris
.run aurorax_sources
```

For further information, you can view what packages are installed using `ipm,/list`. You can also view the package details using `ipm,/query,'idl-aurorax'`.

### Manually

Alternatively, you can install the idl-aurorax library manually by downloading the ZIP file and extracting it into, or adding it to, your IDL path. 

- [Latest packaged release](https://data.aurorax.space/data/software/idl-aurorax/latest.zip)
- [Browse previous releases](https://data.aurorax.space/data/software/idl-aurorax)

## Usage

For usage details, please visit the AuroraX documentation website, and the basic examples section.

- [IDL-AuroraX documentation](https://docs.aurorax.space/code/overview)
- [Basic usage examples](https://docs.aurorax.space/code/basic_usage/overview)

## Updating

If you used `ipm` to install idl-aurorax, you can update it using:

```idl
IDL> ipm,/update,'idl-aurorax'
```

If you installed the code manually, you can download the latest Zip file and overwite the existing files. Then, add and new `.run` commands to your startup file as defined in the "Installation" section above.

- [Latest packaged release](https://data.aurorax.space/data/software/idl-aurorax/latest.zip)
- [Browse previous releases](https://data.aurorax.space/data/software/idl-aurorax)

## Development

### Preparing a new distributable package

When a new release is ready for deployment, there are a few tasks that need to be done.

1. Increment the version number and change the date in `idlpackage.json`.
2. Generate a new distributable Zip file ([more info](https://www.l3harrisgeospatial.com/docs/ipm.html#CREATE))
```
IDL> ipm,/create,'path_to_code',name='idl-aurorax'
```
3. Upload the generated Zip file to https://data.aurorax.space, and update the symlink for latest.zip
4. Create a new release in Github repository
