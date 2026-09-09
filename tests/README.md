# IDL-AuroraX test suite

Unit tests for the IDL-AuroraX library. They need nothing beyond a licensed
IDL install — no mgunit, no other packages.

## Running the tests

From PowerShell:

```powershell
.\tests\run_tests.ps1
```

The script finds IDL, runs the suite, prints the results, and exits non-zero
if anything failed — so it works as a CI step or a pre-push check. If IDL is
somewhere unusual, set `$env:IDL_EXE` or pass `-IdlExe`.

Useful variations:

```powershell
.\tests\run_tests.ps1 -Filter conjunction   # only suites matching a name
.\tests\run_tests.ps1 -Online               # include the network tests
```

From inside an IDL session, which is the quickest way to iterate while
writing a test:

```idl
IDL> cd, 'tests'
IDL> aurorax_run_tests
IDL> aurorax_run_tests, filter='keogram'
IDL> aurorax_run_tests, /online
```

Do not pass `/exit_on_finish` interactively — it closes your IDL session.

On macOS or Linux, where there is no wrapper script, run:

```sh
idl -quiet -e "cd, 'tests' & aurorax_run_tests, /exit_on_finish"
```

## What is covered

Two things shape what these tests do and do not touch. Most of the library
is a client for a remote API, and most of the analysis tools either open
plot windows or need real instrument data. So the suite concentrates on the
parts that can be checked deterministically offline:

- **Query construction.** The conjunction, ephemeris, and data product
  builders are called directly and their JSON payloads asserted on. This is
  the highest-value area — a malformed query is silently accepted by the API
  and comes back with wrong results rather than an error.
- **Pure helpers.** Timestamp parsing, byte and duration formatting, request
  ID extraction, distance pairings, criteria blocks, metadata filters,
  response format templates.
- **Maths.** Great circle interpolation, haversine distances, cadence
  detection, Julian day conversion, field-of-view contours, image
  reorientation, calibration arithmetic.
- **Keograms.** Creation and NaN gap filling, with synthetic image arrays.
- **Consistency.** That the version number agrees across
  `aurorax_version.pro`, `idlpackage.json`, the README badge, and
  `RELEASE_NOTES.md`; and that every public routine and every crib sheet
  actually compiles.

Not covered: anything that opens a plot window, the file readers (they need
real data files), and the network paths beyond the opt-in suite below.

## Offline by default

The default run makes no network calls. Suites whose filename ends in
`_online` are skipped unless `/online` is given; `aurorax_test_api_online`
is the only one today. Keep it that way — a suite that quietly reaches the
network will fail on a plane, and will fail in CI for reasons that have
nothing to do with the change under review.

That constraint has a sharp edge worth knowing about. Several routines
validate their arguments and return early *before* making a request, and
tests rely on that to stay offline. If the argument is not actually invalid,
the routine sails past the guard and hits the API. The datetime parser is
the trap here: it strips separators before measuring length, so `not-a-date`
becomes the eight characters `notadate` and parses happily as `yyyymmdd`.
Use something genuinely unparseable, like `xyz`.

## Adding a test

Drop a `.pro` file in `tests/suites/`. It must define a procedure whose name
matches the filename. The runner discovers it automatically — there is no
list to update.

```idl
pro aurorax_test_my_thing
  compile_opt idl2

  atest_suite, 'my thing -- some behaviour'
  atest_equal, my_function(1), 2, 'it doubles its input'
end
```

Name it `*_online.pro` if it needs the network.

Available assertions, all from `aurorax_test_framework.pro`:

| Assertion | Checks |
| --- | --- |
| `atest_equal, actual, expected, desc` | equality; copes with `!null`, scalars, strings, arrays |
| `atest_not_equal, actual, expected, desc` | inequality |
| `atest_true, value, desc` / `atest_false, ...` | truthiness |
| `atest_null, value, desc` / `atest_not_null, ...` | `!null`-ness |
| `atest_close, actual, expected, tol, desc` | floats, within a tolerance |
| `atest_contains, haystack, needle, desc` | substring present |
| `atest_not_contains, haystack, needle, desc` | substring absent |
| `atest_has_key, hash, key, desc` | hash key present |
| `atest_has_tag, struct, tag, desc` | struct tag present |
| `atest_n_elements, value, n, desc` | element count |
| `atest_valid_json, str, desc, parsed=q` | parses as JSON, hands back the hash |
| `atest_raises, 'statement', desc` | the statement errors |
| `atest_no_raise, 'statement', desc` | the statement does not error |
| `atest_ok, condition, desc, detail=...` | the primitive the rest are built on |

`atest_note, 'message'` writes a line into the output without asserting
anything. Use it before a call that prints its own error message, so whoever
reads the log knows the noise is deliberate.

## Conventions

**Pin bugs rather than working around them.** Several tests assert behaviour
that is wrong, marked `KNOWN BUG` or `KNOWN LIMITATION` with an explanation
and, where it is short, the fix. This keeps the suite green so a real
regression stands out, while keeping the defect visible. When one gets
fixed, its test will fail — update it to expect the correct behaviour. The
ones recorded today:

- `aurorax_create_metadata_filter` computes a logical operator from its
  keywords and then hardcodes `'AND'`, so `/operator_or` is silently dropped.
- `__aurorax_perform_dark_frame_calibration` clamps negatives with
  `new_images[where(new_images lt 0)] = 0`; when nothing is negative `where`
  returns `-1`, which IDL reads as the last element, so the final pixel is
  wrongly zeroed.
- The same routine cannot handle a single 2-D frame at all: its reform guard
  is undone by the `long()` on the next line, and the frame loop then runs
  off the end of the array.
- `__aurorax_time2string` has no hours handling and takes minutes modulo 60,
  so an hour renders as `0 minutes, 0.0 seconds`.
- `aurorax_create_advanced_distances_hash` faults, rather than returning
  cleanly, when the criteria block count is out of range.
- `__aurorax_data_product_create_post_str` assigns the data product type
  filter to a tag that does not exist on the struct it targets, so passing
  `data_product_types` faults.
- The datetime parser's leap years come from a list hardcoded to 1980–2040,
  so February in a leap year outside that span is treated as 28 days.

**Build inputs fresh for each test.** IDL passes by reference, and several
library routines modify their arguments in place — the calibration helpers
and the metadata filter builder both do.

**Watch for trailing dimensions.** IDL drops a trailing length-1 dimension,
so `intarr(8,8,1)` really is `[8,8]`. This bites both the library and the
tests; use a genuine multi-frame array when testing per-frame behaviour.

## How the runner loads the library

`aurorax_test_load_library` compiles the library into the session. It does
not use `@aurorax_startup`, because that batch file checks GitHub for a new
version and aborts awkwardly when the AACGM coefficient files are missing —
neither of which belongs in a test run.

Two details make it work. Most source files hold several routines and are
named after none of them, so they never auto-resolve; `resolve_routine` with
`/compile_full_file` compiles the whole file and then raises because the
routine it was asked for does not exist, and that error is swallowed. And
order matters, because IDL cannot tell `foo(x, /kw)` from an array subscript
until `foo` is compiled — so the loader compiles in the order
`aurorax_startup.pro` declares, then sweeps up anything that file does not
mention.
