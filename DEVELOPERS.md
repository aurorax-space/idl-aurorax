# Development

## Setting up for development

This software is set up to be developed using Windows. In order to get your Windows environment set up for development, a few things need to be done:

1. Ensure Git is installed
2. Clone the repository

## Running the tests

The test suite lives in `tests/` and needs nothing but a licensed IDL install.

```powershell
.\tests\run_tests.ps1
```

It exits non-zero if anything fails, so it works as a pre-push check. Add
`-Online` to include the tests that talk to the AuroraX API; the default run
is entirely offline. See [tests/README.md](tests/README.md) for how to add a
suite and for the conventions the existing ones follow.

## Preparing a new distributable package

When a new release is ready for deployment, there are a few tasks that need to be done.

1. Increment the version number and change the date in `idlpackage.json`, `aurorax_version.pro`, and `README.md`.

    These have drifted apart before. `aurorax_test_version` cross-checks all
    of them (plus the newest `RELEASE_NOTES.md` heading), so running the
    test suite after the bump will catch a missed file.
2. Generate a new distributable Zip file ([more info](https://www.l3harrisgeospatial.com/docs/ipm.html#CREATE))

    ```idl
    IDL> ipm,/create,'path_to_code',name='idl-aurorax'
    ```

3. Upload the generated Zip file to https://data.aurorax.space, and update the symlink for latest.zip
4. Create a new release in Github repository
