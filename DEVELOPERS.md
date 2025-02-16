# Development

## Setting up for development

This software is set up to be developed using Windows. In order to get your Windows environment set up for development, a few things need to be done:

1. Ensure Git is installed
2. Clone the repository
3. Set up dependencies

    ```
    cd <path to cloned repo>
    ./developer_setup.ps1
    ```

## Generating the documentation

The docs are presently an alpha state item. To build them:

```idl
idldoc,root='path\to\idl-aurorax\src',output='path\to\idl-aurorax\docs'
```

## Preparing a new distributable package

When a new release is ready for deployment, there are a few tasks that need to be done.

1. Increment the version number and change the date in `idlpackage.json`, `aurorax_helpers.pro`, and `README.md`.
2. Generate a new distributable Zip file ([more info](https://www.l3harrisgeospatial.com/docs/ipm.html#CREATE))

    ```idl
    IDL> ipm,/create,'path_to_code',name='idl-aurorax'
    ```

3. Upload the generated Zip file to https://data.aurorax.space, and update the symlink for latest.zip
4. Create a new release in Github repository
