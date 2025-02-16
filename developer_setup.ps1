# Define the target directory
$targetDir = "libs/idldoc"

# Check if the directory exists
if (Test-Path -Path $targetDir) {
    # Remove the directory recursively
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Host "Removed existing directory: $targetDir"
} else {
    Write-Host "Directory does not exist: $targetDir"
}

# Navigate to 'libs' directory
Set-Location -Path "libs"

# Clone the Git repository with specific branch and depth
git clone --depth 1 --branch IDLDOC_3_6_4 https://github.com/mgalloy/idldoc

# Navigate to 'libs/idldoc'
Set-Location -Path "idldoc"

# Update submodules (initialize and fetch recursively)
git submodule update --init --recursive

# Navigate to 'libs/idldoc/lib/mgcmake' and pull updates from master
Set-Location -Path "lib/mgcmake"
git pull origin master

# Navigate to 'libs/idldoc/lib' and pull updates from master
Set-Location -Path ".."
git pull origin master

# Return to the original directory if needed
Set-Location -Path "../../.."
