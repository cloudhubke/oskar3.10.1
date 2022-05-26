################################################################################
# report generation
################################################################################
Function showLog
{
    Get-Content "$INNERWORKDIR\test.log" | Out-GridView -Title "$INNERWORKDIR\test.log";comm
}

Function log([array]$log)
{
    ForEach ($l in $log)
    {
        Write-Host $l
        $l | Add-Content "$INNERWORKDIR\test.log"
    }
    comm
}

Function createReport
{
    $date = $(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ")
    $date | Add-Content "$env:TMP\testProtocol.txt"
    $global:badtests = $null
    new-item $env:TMP\oskar-junit-report -itemtype directory
    ForEach ($dir in (Get-ChildItem -Path $env:TMP  -Directory -Filter "*.out"))
    {
        $reportFound = $false
        If ($(Get-ChildItem -filter "*.xml" -path $dir.FullName | Measure-Object | Select -ExpandProperty Count) -gt 0) {
          Copy-Item -Path "$($dir.FullName)\*.xml" $env:TMP\oskar-junit-report
        }
        Write-Host "Looking at directory $($dir.BaseName)"
        If(Test-Path -PathType Leaf -Path "$($dir.FullName)\UNITTEST_RESULT_EXECUTIVE_SUMMARY.json")
            {
                        $reportFound = $true
                        If(-Not($(Get-Content "$($dir.FullName)\UNITTEST_RESULT_EXECUTIVE_SUMMARY.json") -eq "true"))
                        {
                            $global:result = "BAD"
                            $file = $($dir.BaseName).Substring(0,$($dir.BaseName).Length-4)+".stdout.log"
                            Write-Host "Bad result in $file"
                            "Bad result in $file" | Add-Content "$env:TMP\testProtocol.txt"
                            $global:badtests = $global:badtests + "Bad result in $file`r`n"
                        }   
            }
        If(Test-Path -PathType Leaf -Path "$($dir.FullName)\UNITTEST_RESULT_CRASHED.json")
            {
                        $reportFound = $true
                        If(-Not($(Get-Content "$($dir.FullName)\UNITTEST_RESULT_CRASHED.json") -eq "false"))
                        {
                            $global:result = "BAD"
                            $file = $($dir.BaseName).Substring(0,$($dir.BaseName).Length-4)+".stdout.log"
                            Write-Host "Crash occured in $file"
                            $global:hasTestCrashes = $True
                            "Crash occured in $file" | Add-Content "$env:TMP\testProtocol.txt"
                            $global:badtests = $global:badtests + "Crash occured in $file`r`n"
                        }   
            }
        If ($reportFound -ne $true)
            {
                Write-Host "No Testresult found at directory $($dir.BaseName)"
                $global:result = "BAD"
                "No Testresult found at directory $($dir.BaseName)" | Add-Content "$env:TMP\testProtocol.txt"
                $global:badtests = $global:badtests + "No Testresult found at directory $($dir.BaseName)`r`n"   
            }
    }
    $global:result | Add-Content "$env:TMP\testProtocol.txt"
    If($global:ENABLE_REPORT_DUMPS -eq "on" -and (Get-ChildItem -Path "$global:COREDIR" -Filter "arango*.dmp" -Recurse -ErrorAction Continue -Force))
    {
        Write-Host "7zip -Path "$global:ARANGODIR\build\bin\$BUILDMODE\arango*.exe "-DestinationPath "$INNERWORKDIR\crashreport-$date.7z
        7zip -Path "$global:ARANGODIR\build\bin\$BUILDMODE\arango*.exe" -DestinationPath "$INNERWORKDIR\crashreport-$date.7z"
        ForEach ($core in (Get-ChildItem -Path "$global:COREDIR" -Filter "arango*.dmp" -Recurse -ErrorAction SilentlyContinue))
        {
            Write-Host "7zip -Path $($core.FullName) -DestinationPath `"$INNERWORKDIR\crashreport-$date.7z`""   
            7zip -Path $($core.FullName) -DestinationPath "$INNERWORKDIR\crashreport-$date.7z"
            Write-Host "Remove-Item $($core.FullName)"
            Remove-Item $($core.FullName)
        }
        ForEach ($pdb in (Get-ChildItem -Path "$global:ARANGODIR\build\bin\$BUILDMODE\" -Filter "arango*.pdb" -Recurse -ErrorAction SilentlyContinue))
        {
            Write-Host "7zip -Path $($pdb.FullName) -DestinationPath `"$INNERWORKDIR\crashreport-$date.7z`""
            7zip -Path $($pdb.FullName) -DestinationPath "$INNERWORKDIR\crashreport-$date.7z"
        }
    }
    If(Test-Path -PathType Leaf -Path "$global:ARANGODIR\innerlogs.7z")
    {
        Remove-Item -Force "$global:ARANGODIR\innerlogs.7z"
    }
    Write-Host "7zip -Path `"$env:TMP\`" -DestinationPath `"$global:ARANGODIR\innerlogs.7z`""
    7zip -Path "$env:TMP\" -DestinationPath "$global:ARANGODIR\innerlogs.7z"
    ForEach ($log in $(Get-ChildItem -Path $global:ARANGODIR -Filter "*.log"))
    {
        Write-Host "7zip -Path $($log.FullName)  -DestinationPath `"$INNERWORKDIR\testreport-$date.7z`""
        7zip -Path $($log.FullName) -DestinationPath "$INNERWORKDIR\testreport-$date.7z"
    }
    ForEach ($archive in $(Get-ChildItem -Path $global:ARANGODIR -Filter "*.7z"))
    {
        Write-Host "7zip -Path $($archive.FullName) -DestinationPath `"$INNERWORKDIR\testreport-$date.7z`""
        7zip -Path $($archive.FullName) -DestinationPath "$INNERWORKDIR\testreport-$date.7z"
    }
    Write-Host "7zip -Path $env:TMP\testProtocol.txt -DestinationPath `"$INNERWORKDIR\testreport-$date.7z`""
    7zip -Path "$env:TMP\testProtocol.txt" -DestinationPath "$INNERWORKDIR\testreport-$date.7z"

    log "$date $TESTSUITE $global:result M:$MAINTAINER $BUILDMODE E:$ENTERPRISEEDITION $STORAGEENGINE",$global:repoState,$global:repoStateEnterprise,$badtests
    If(Test-Path -PathType Leaf -Path "$INNERWORKDIR\testfailures.txt")
    {
        Remove-Item -Force "$INNERWORKDIR\testfailures.txt"
    }

    If($global:result -eq "BAD" -Or $global:hasTestCrashes)
    {
        $global:oskarErrorMessage | Add-Content "$INNERWORKDIR\testfailures.txt"
        ForEach ($file in (Get-ChildItem -Path $env:TMP -Filter "testfailures.txt" -Recurse).FullName)
        {
            Get-Content $file | Add-Content "$INNERWORKDIR\testfailures.txt"; comm
        }
    }
}

################################################################################
# Test main control
################################################################################

Function runTests
{
    If (Test-Path -PathType Container -Path $env:TMP)
    {
        Remove-Item -Recurse -Force -Path $env:TMP -Exclude "$env:TMP\OpenSSL"
    }
    Else
    {
        New-Item -ItemType Directory -Path $env:TMP
    }
    Push-Location $pwd
    Set-Location $global:ARANGODIR
    ForEach ($log in $(Get-ChildItem -Filter "*.log"))
    {
        Remove-Item -Recurse -Force $log 
    }
    Pop-Location

    Switch -Regex ($TESTSUITE)
    {
        "cluster"
        {
            registerClusterTests
            LaunchController $global:TESTSUITE_TIMEOUT
            createReport  
            Break
        }
        "single"
        {
            registerSingleTests
            LaunchController $global:TESTSUITE_TIMEOUT
            createReport
            Break
        }
        "catchtest"
        {
            registerTest -testname "catch"
            LaunchController $global:TESTSUITE_TIMEOUT
            createReport
            Break
        }
        "resilience"
        {
            Write-Host "resilience tests currently not implemented"
            $global:result = "BAD"
            Break
        }
        "tests"
        {
            registerTests
            LaunchController $global:TESTSUITE_TIMEOUT
            createReport
            Break
        }
        "*"
        {
            Write-Host "Unknown test suite $TESTSUITE"
            $global:result = "BAD"
            Break
        }
    }

    If($global:result -eq "GOOD")
    {
        Set-Variable -Name "ok" -Value $true -Scope global
    }
    Else
    {
        Set-Variable -Name "ok" -Value $false -Scope global
    }
}

Function waitForTimeWaitSockets() {
    $TimeWait = 0
    do {
      $TimeWait = (Get-NetTCPConnection -State TimeWait -ErrorAction SilentlyContinue | Measure-Object).Count
      If ($TimeWait -gt 2500) {
        Write-Host "waiting for connections to go away ${TimeWait}"
        Start-Sleep 20
      }
    } while ($TimeWait -gt 2500)
}

Function launchTest($which) {
    waitForTimeWaitSockets
    Push-Location $pwd
    Set-Location $global:ARANGODIR; comm
    $arangosh = "$global:ARANGODIR\build\bin\$BUILDMODE\arangosh.exe"
    $test = $global:launcheableTests[$which]
    Write-Host "Test: " $test['testname'] " - " $test['identifier']
    Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
    Write-Host $arangosh " --- " $test['commandline'] 
    Write-Host "-RedirectStandardOutput " $test['StandardOutput']
    Write-Host "-RedirectStandardError " $test['StandardError']

    $process = $(Start-Process -FilePath "$arangosh" -ArgumentList $test['commandline'] -RedirectStandardOutput $test['StandardOutput'] -RedirectStandardError $test['StandardError'] -PassThru)
    
    $global:launcheableTests[$which]['pid'] = $process.Id
    $global:launcheableTests[$which]['running'] = $true
    $global:launcheableTests[$which]['launchDate'] = $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))
    If(-not($process.ExitCode -eq $null))
    {
        Write-Host "Error: Launching Test"
        $process | Format-List -Property *
    }

    $str=$($test | where {($_.Name -ne "commandline")} | Out-String)
    Write-Host $str
    $global:launcheableTests[$which]['process'] = $process
    Pop-Location
}

Function registerTest($testname, $index, $bucket, $filter, $moreParams, $cluster, $weight, $sniff, [switch]$vst, [switch]$http2,[switch]$encrypt,[switch]$ssl)
{
    Write-Host "$global:ARANGODIR\UnitTests\OskarTestSuitesBlockList"
    $checkname = If ($vst) { $testname + "_$vst" } ElseIf ($http2) { $testname + "_$http2" } Else { $testname }
    
    If(-Not(Select-String -Path "$global:ARANGODIR\UnitTests\OskarTestSuitesBlockList" -pattern "^$checkname$" | select line))
    {
        $testWeight = 1
        $testparams = ""
        $dumpAgencyOnError = ""

        $output = $testname.replace("*", "all")
        If ($index) {
          $output = $output+"_$index"
        }
        If ($filter) {
           $testparams = $testparams+" --test $filter"
        }
        If ($bucket) {
            $testparams = $testparams+" --testBuckets $bucket"
        }
        If ($cluster -eq $true)
        {
            $testWeight = 4
            $cluster = "true"
            $dumpAgencyOnError = "true"
        }
        Else
        {
            $cluster = "false"
            $dumpAgencyOnError = "false"
        }
        If ($testname -eq "agency")
        {
            $dumpAgencyOnError = "true"
        }
        If ($weight) {
          $testWeight = $weight
        }

        If ($vst) {
          $testparams = $testparams + " --vst true"
        }

        If ($ssl) {
          $testparams = $testparams + " --protocol ssl"
        }

        If ($http2) {
          $testparams = $testparams + " --http2 true"
        }

        If ($encrypt) {
          $testparams = $testparams + " --encryptionAtRest true"
        }

        If ($sniff) {
          $testparams = $testparams + " --sniff true --sniffProgram `"$global:TSHARK`" --sniffDevice $global:dumpDevice"
        }
        
        $testparams = $testparams + " --cluster $cluster --coreCheck true --storageEngine $STORAGEENGINE --minPort $global:portBase --maxPort $($global:portBase + 99) --skipNondeterministic $global:SKIPNONDETERMINISTIC --skipTimeCritical $global:SKIPTIMECRITICAL --writeXmlReport true --skipGrey $global:SKIPGREY --dumpAgencyOnError $dumpAgencyOnError --onlyGrey $global:ONLYGREY --buildType $BUILDMODE --disableMonitor true"

        New-Item -Path "$env:TMP\$output.out" -ItemType Directory
        $testparams = $testparams + " --testOutput $env:TMP\$output.out"
        $testparams = $testparams + " " + $moreParams
        If (-Not ([string]::IsNullOrEmpty($global:RUBY))) {
          $testparams = $testparams + " --ruby " + $global:RUBY
        }
        
        $PORT = Get-Random -Minimum 20000 -Maximum 65535
        $i = $global:testCount
        $global:testCount = $global:testCount+1
        $global:launcheableTests += @{
          running=$false;
          weight=$testWeight;
        testname=$testname;
        identifier=$output;
          commandline=" -c $global:ARANGODIR\etc\relative\arangosh.conf --log.level warning --server.endpoint tcp://127.0.0.1:$PORT --javascript.execute $global:ARANGODIR\UnitTests\unittest.js -- $testname $testparams";
          StandardOutput="$global:ARANGODIR\$output.stdout.log";
          StandardError="$global:ARANGODIR\$output.stderr.log";
          pid=-1;
        }
        $global:maxTestCount = $global:maxTestCount+1
        
        $global:portBase = $($global:portBase + 100)
    }
    Else
    {
        Write-Host "Test suite $checkname skipped by UnitTests/OskarTestSuitesBlockList"
    }
    comm
}

Function StopProcessWithChildren ($PidToKill, $WaitTimeout)
{
    Write-Host "Killing $PidToKill with descedants!"
    $stopProc = Get-Process -Id $PidToKill

    If ($global:PSKILL_EXE) {
        Invoke-Expression "$global:PSKILL_EXE -t $PidToKill" | Out-Null
    } Else {
        Stop-Process -Force -Id $PidToKill
    }

    While (-Not $stopProc.HasExited) {
        Write-Host "Waiting $PidToKill to stop for ${WaitTimeout}s..."
    }
}

Function LaunchController($seconds)
{
    $timeSlept = 0;
    $nextLauncheableTest = 0
    $currentScore = 0
    $currentRunning = 1
    $maxLauncheableTests = $global:launcheableTests.Length
    $numberTestsSlots = [math]::Round($global:numberSlots * 0.9) # Should leave 10% of slots free for $global:numberSlots > 4
    While (($seconds -gt 0) -and (($currentRunning -gt 0) -or ($nextLauncheableTest -lt $maxLauncheableTests))) {
        while (($currentScore -lt $numberTestsSlots) -and ($nextLauncheableTest -lt $global:maxTestCount)) {
            Write-Host "Launching $nextLauncheableTest '" $global:launcheableTests[$nextLauncheableTest ]['identifier'] "'"
            launchTest $nextLauncheableTest 
            $currentScore = $currentScore+$global:launcheableTests[$nextLauncheableTest ]['weight']
            Start-Sleep 20
            $seconds = $seconds - 20
            $nextLauncheableTest = $nextLauncheableTest+1
        }
        $currentRunning = 0
        $currentRunningNames = @()
        ForEach ($test in $global:launcheableTests) {
            If ($test['running']) {
                If ($test['process'].HasExited) {
                    $currentScore = $currentScore - $test['weight']
                    Write-Host "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ')) Testrun finished: "$test['identifier'] $test['launchdate']
                    $str=$($test | where {($_.Name -ne "commandline")} | Out-String)
                    $test['running'] = $false
                }
                Else {
                    $currentRunningNames += $test['identifier']
                    $currentRunning = $currentRunning+1
                }
            }
        }
        Start-Sleep 5
        $a = $currentRunningNames -join ","
        Write-Host "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ')) - Waiting  - "$seconds" - Running Tests: "$a
        $seconds = $seconds - 5
    }
    If ($seconds -lt 1) {
      Write-Host "tests timeout reached. Current state of worker jobs:"
    }
    Else {
      Write-Host "tests done. Current state of worker jobs:"
    }
    $str=$global:launcheableTests | Out-String
    Write-Host $str

    Get-WmiObject win32_process | Out-File -filepath $env:TMP\processes-before.txt
    Write-Host "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ')) we have $currentRunning test(s) that timed out! Currently running processes:"
    $SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
    ForEach ($test in $global:launcheableTests) {
        If ($test['pid'] -gt 0 -And $test['running'] -And (Get-Process -Id $test['pid'] -ErrorAction SilentlyContinue)) {
            $global:oskarErrorMessage = $global:oskarErrorMessage + "Oskar is killing this test due to timeout: " + $test['testname'] + "`n"
            Write-Host "Testrun timeout:"
            $str = $($test | where {($_.Name -ne "commandline")} | Out-String)
            Write-Host $str
            StopProcessWithChildren $test['pid'] 3
            $global:result = "BAD"
        }
    }
    Get-WmiObject win32_process | Out-File -filepath $env:TMP\processes-after.txt 
    comm
}
