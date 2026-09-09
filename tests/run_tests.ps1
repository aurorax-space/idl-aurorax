<#
.SYNOPSIS
    Run the IDL-AuroraX test suite.

.DESCRIPTION
    Locates an IDL install, runs the suite, prints the results and exits
    with 0 on success or 1 on failure -- so it can be used directly as a CI
    step or a pre-push check.

    Results are read back from a log file rather than from stdout. IDL on
    Windows does not reliably flush stdout into a pipe before the process
    exits, so a piped run can otherwise lose the tail of its own output,
    summary included.

.PARAMETER Online
    Also run the suites that talk to the AuroraX API.

.PARAMETER Filter
    Only run suites whose name contains this substring.

.PARAMETER IdlExe
    Path to idl.exe. Defaults to $env:IDL_EXE, otherwise the newest install
    found under Program Files.

.EXAMPLE
    .\run_tests.ps1
    .\run_tests.ps1 -Filter conjunction
    .\run_tests.ps1 -Online
#>
[CmdletBinding()]
param(
    [switch] $Online,
    [string] $Filter,
    [string] $IdlExe
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------
# locate IDL
# ---------------------------------------------------------------
if (-not $IdlExe) { $IdlExe = $env:IDL_EXE }

if (-not $IdlExe) {
    $candidates = @()
    foreach ($vendor in @('NV5', 'Harris', 'Exelis', 'ITT')) {
        $root = Join-Path ${env:ProgramFiles} $vendor
        if (Test-Path $root) {
            $found = Get-ChildItem -Path $root -Filter 'idl.exe' -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -like '*bin.x86_64*' }
            $candidates += $found
        }
    }
    # newest install wins
    $best = $candidates | Sort-Object FullName -Descending | Select-Object -First 1
    if ($best) { $IdlExe = $best.FullName }
}

if (-not $IdlExe -or -not (Test-Path $IdlExe)) {
    Write-Host 'ERROR: could not find idl.exe.' -ForegroundColor Red
    Write-Host '       Set $env:IDL_EXE to its full path, or pass -IdlExe.'
    exit 1
}

# ---------------------------------------------------------------
# build the IDL command
# ---------------------------------------------------------------
$testsDir = $PSScriptRoot
$logFile = Join-Path ([System.IO.Path]::GetTempPath()) "idl-aurorax-tests-$PID.log"

$idlArgs = "logfile='$logFile', /exit_on_finish"
if ($Online) { $idlArgs = "$idlArgs, /online" }
if ($Filter) { $idlArgs = "$idlArgs, filter='$Filter'" }

$statement = "cd, '$testsDir' & aurorax_run_tests, $idlArgs"

Write-Host "Running IDL-AuroraX test suite"
Write-Host "  IDL:   $IdlExe"
Write-Host ""

# stdout is discarded -- the library under test prints its own expected
# error messages there, and the log file is the authoritative results copy
& $IdlExe -quiet -e $statement | Out-Null
$idlExit = $LASTEXITCODE

# ---------------------------------------------------------------
# report
# ---------------------------------------------------------------
if (Test-Path $logFile) {
    Get-Content $logFile
    Remove-Item $logFile -ErrorAction SilentlyContinue
} else {
    Write-Host 'ERROR: the test run produced no log file.' -ForegroundColor Red
    Write-Host '       IDL may have failed to start, or crashed before the suite began.'
    exit 1
}

if ($idlExit -ne 0) {
    Write-Host ''
    Write-Host 'TESTS FAILED' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'TESTS PASSED' -ForegroundColor Green
exit 0
