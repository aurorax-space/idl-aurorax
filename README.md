<a href="https://aurorax.space/"><img alt="AuroraX" src="logo.svg" height="60"></a>

![Stable version](https://img.shields.io/badge/Latest%20stable%20release-v0.7.3-orange)
![IDL version required](https://img.shields.io/badge/IDL-8.7.2%2B-blue)
[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://github.com/aurorax-space/idl-aurorax/blob/main/LICENSE)
[![DOI](https://img.shields.io/badge/DOI-10.3389/fspas.2022.1009450-blue)](https://www.frontiersin.org/articles/10.3389/fspas.2022.1009450/full)

IDL-AuroraX is an IDL library for interacting with [AuroraX](https://aurorax.space), a project working to be the world's first and foremost data platform for auroral science. The primary objective of AuroraX is to enable mining and exploration of existing and future auroral data, enabling key science and enhancing the benefits of the world's investment in auroral instrumentation. This will be accomplished with the development of key systems/standards for uniform metadata generation and search, image content analysis, interfaces to leading international tools, and a community involvement that includes more than 80% of the world's data providers.

IDL-AuroraX officially supports IDL 8.7.2+.

Some links to help:
- [AuroraX main website](https://aurorax.space)
- [IDL-AuroraX documentation](https://docs.aurorax.space/code/overview)
- [Latest packaged release](https://data.aurorax.space/data/software/idl-aurorax/latest.zip)
- [Browse previous releases](https://data.aurorax.space/data/software/idl-aurorax)

## Limitations

Please note, this IDL library only provides the ability to **retrieve** data from the AuroraX platform. It does not have functions for uploading or editing data on AuroraX. Please use the Python library, [PyAuroraX](https://github.com/aurorax-space/pyaurorax) for this functionality.

## Installation

Installation can be done two different ways: 1) using the `ipm` command (recommended), or 2) manually adding the files to your IDL path.

You can view all previous versions by browsing the AuroraX data tree [here](https://data.aurorax.space/data/software/idl-aurorax).

### Using ipm (recommended)

Since IDL 8.7.1, there exists an IDL package manager called [ipm](https://www.l3harrisgeospatial.com/docs/ipm.html#INSTALL). We can use this to install the idl-aurorax library with a single command. This is the recommended way of installing the IDL-AuroraX library.

1. From the IDL command prompt, run the following:

    ```idl
    IDL> ipm,/install,'https://data.aurorax.space/data/software/idl-aurorax/latest.zip'
    ```

2. Add the following to your startup file, or run the command manually using the IDL command prompt:

    ```
    [ open your startup.pro file and put the following in it ]
    .run aurorax_startup
    ```

3. Reset your IDL session by either clicking the Reset button in the IDL editor or by typing `.reset` into the IDL command prompt. If you compiled the code manually in step 2 (instead of adding to your startup file), skip this step.

For further information, you can view what packages are installed using `ipm,/list`. You can also view the package details using `ipm,/query,'idl-aurorax'`.

### Manually

Alternatively, you can install the idl-aurorax library manually by downloading the ZIP file and extracting it into, or adding it to, your IDL path. 

1. Download the latest release [here](https://data.aurorax.space/data/software/idl-aurorax/latest.zip)
2. Extract the zip file into your IDL path (or add it as a directory to your IDL path)
3. Add the following to your startup file (or run the command manually using the IDL command prompt).

    ```
    [ open your startup.pro file and put the following in it ]
    .run aurorax_startup
    ```

4. Reset your IDL session by either clicking the Reset button in the IDL editor or by typing `.reset` into the IDL command prompt.

Some additional resources about the release files are:

- [Latest packaged release](https://data.aurorax.space/data/software/idl-aurorax/latest.zip)
- [Browse previous releases](https://data.aurorax.space/data/software/idl-aurorax)

### Bleeding edge

If you want to install the most bleeding-edge version, use `ipm` and the Github repository URL:

1. Install library from Github URL with the following command:

    ```idl
    IDL> ipm,/install,'https://github.com/aurorax-space/idl-aurorax'
    ```

2. Add the following to your startup file (or run the command manually using the IDL command prompt).

    ```
    [ open your startup.pro file and put the following in it ]
    .run aurorax_startup
    ```

3. Reset your IDL session by either clicking the Reset button in the IDL editor or by typing `.reset` into the IDL command prompt.

## Updating

If you used `ipm` to install idl-aurorax, you can update it using:

```idl
IDL> ipm,/update,'idl-aurorax'
IDL> .reset
```

If you installed the code manually, you can download the latest Zip file and overwite the existing files. Then, add any new `.run` commands to your startup file as defined in the "Installation" section above.

- [Latest packaged release](https://data.aurorax.space/data/software/idl-aurorax/latest.zip)
- [Browse previous releases](https://data.aurorax.space/data/software/idl-aurorax)

## Usage

For usage details, please visit the AuroraX documentation website, and the basic examples section.

- [IDL-AuroraX documentation](https://docs.aurorax.space/code/overview)
- [Basic usage examples](https://docs.aurorax.space/code/basic_usage/overview)

## Development

### Preparing a new distributable package

When a new release is ready for deployment, there are a few tasks that need to be done.

1. Increment the version number and change the date in `idlpackage.json`, `aurorax_helpers.pro`, and `README.md`.
2. Generate a new distributable Zip file ([more info](https://www.l3harrisgeospatial.com/docs/ipm.html#CREATE))

    ```idl
    IDL> ipm,/create,'path_to_code',name='idl-aurorax'
    ```

3. Upload the generated Zip file to https://data.aurorax.space, and update the symlink for latest.zip
4. Create a new release in Github repository
