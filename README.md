<a href="https://aurorax.space/"><img alt="AuroraX" src="logo.svg" height="60"></a>

![idl-required](https://img.shields.io/badge/IDL%20Version-8.8%2B-blue)
[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://lbesson.mit-license.org/)

IDL-AuroraX is an IDL library for interacting with [AuroraX](https://aurorax.space), a project working to be the world's first and foremost data platform for auroral science. The primary objective of AuroraX is to enable mining and exploration of existing and future auroral data, enabling key science and enhancing the benefits of the world's investment in auroral instrumentation. This will be accomplished with the development of key systems/standards for uniform metadata generation and search, image content analysis, interfaces to leading international tools, and a community involvement that includes more than 80% of the world's data providers.

IDL-AuroraX officially supports IDL 8.8+ (limited testing on older versions).

Some links to help:
- [AuroraX main website](https://aurorax.space)
- [IDL-AuroraX documentation](https://docs.aurorax.space/code/overview)
- [IDL-AuroraX API Reference](https://docs.aurorax.space/code/idlaurorax_api_reference)

## Capabilities

Please note, this IDL library only provides the ability to **retrieve** data from the AuroraX platform. It does not have functions for uploading or editing data on AuroraX. Please use the Python library, [PyAuroraX](https://github.com/aurorax-space/pyaurorax) for this functionality.

## Installation

Installation can be done two different ways: 1) using the [ipm command](https://www.l3harrisgeospatial.com/docs/ipm.html#INSTALL), or 2) manually adding the files to your IDL path.

### Using ipm

Since IDL 8.7.1, there exists an IDL package manager called [ipm](https://www.l3harrisgeospatial.com/docs/ipm.html#INSTALL). We can use this to install the idl-aurorax library with a single command.

On the IDL command prompt, run the following:

```
IDL> ipm,/install,'https://github.com/aurorax-space/idl-aurorax/archive/refs/heads/main.zip'
```

To upgrade, run the following:

```
IDL> ipm,/upgrade,'https://github.com/aurorax-space/idl-aurorax/archive/refs/heads/main.zip'
```

### Manually

Alternatively, you can install the idl-aurorax library manually by downloading the ZIP file and extracting it into, or adding it to, your IDL path.
