$HDD = $(Split-Path -Qualifier $ENV:WORKSPACE)
If(-Not(Test-Path -PathType Container -Path "$HDD\$env:NODE_NAME"))
{
    New-Item -ItemType Directory -Path "$HDD\$env:NODE_NAME"
}
$OSKARDIR = "$HDD\$env:NODE_NAME"
Set-Location $OSKARDIR
If(-Not(Test-Path -PathType Container -Path "$OSKARDIR\oskar"))
{
    git clone https://github.com/neunhoef/oskar
    Set-Location "$OSKARDIR\oskar"
}
Set-Location "$OSKARDIR\oskar"
Import-Module "$OSKARDIR\oskar\powershell\oskar.psm1"
If($Error -ne 0)
{
    Write-Host "Did not find oskar and helpers"
    Exit 1
}

$($env:EDITION)

lockDirectory
updateOskar
clearResults

. $env:EDITION
. $env:STORAGE_ENGINE
. $env:TEST_SUITE

switchBranches $env:ARANGODB_BRANCH $env:ENTERPRISE_BRANCH
If (-Not($Error)) 
{
    oskar1
}

Set-Location "$OSKARDIR\oskar"
moveResultsToWorkspace
unlockDirectory

exit $Error