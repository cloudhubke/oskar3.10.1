Import-Module "$PSScriptRoot\lib\Utils.psm1"

################################################################################
# Test control
################################################################################

Function global:registerSingleTests()
{
    noteStartAndRepoState

    Write-Host "Registering tests..."

    $global:TESTSUITE_TIMEOUT = 9000

    registerTest -testname "upgrade_data_3.2.*"
    registerTest -testname "upgrade_data_3.3.*"
    registerTest -testname "upgrade_data_3.4.*"
    registerTest -testname "upgrade_data_3.5.*"
    registerTest -testname "upgrade_data_3.6.*"
    registerTest -testname "upgrade_data_3.7.*"
    registerTest -testname "replication_static" -weight 2
    registerTest -testname "shell_server"
    registerTest -testname "replication_ongoing_frompresent" -weight 2
    registerTest -testname "replication_ongoing_global_spec" -weight 2
    registerTest -testname "replication_ongoing_global" -weight 2
    registerTest -testname "replication_ongoing" -weight 2
    registerTest -testname "replication_aql" -weight 2
    registerTest -testname "replication_fuzz" -weight 2
    registerTest -testname "replication_random" -weight 2
    registerTest -testname "replication_sync" -weight 2
    #FIXME: No LDAP tests for Windows at the moment
    #registerTest -testname "ldaprole" -ldapHost arangodbtestldapserver
    #registerTest -testname "ldaprolesimple" -ldapHost arangodbtestldapserver
    #registerTest -testname "ldapsearch" -ldapHost arangodbtestldapserver
    #registerTest -testname "ldapsearchsimple" -ldapHost arangodbtestldapserver
    registerTest -testname "recovery" -index "0" -bucket "4/0"
    registerTest -testname "recovery" -index "1" -bucket "4/1"
    registerTest -testname "recovery" -index "2" -bucket "4/2"
    registerTest -testname "recovery" -index "3" -bucket "4/3"
    registerTest -testname "shell_server_aql" -index "0" -bucket "5/0"
    registerTest -testname "shell_server_aql" -index "1" -bucket "5/1"
    registerTest -testname "shell_server_aql" -index "2" -bucket "5/2"
    registerTest -testname "shell_server_aql" -index "3" -bucket "5/3"
    registerTest -testname "shell_server_aql" -index "4" -bucket "5/4"
    registerTest -testname "shell_api" -index "http" -sniff true
    registerTest -testname "shell_api" -index "https" -ssl -sniff true
    registerTest -testname "shell_client" -index "http"
    registerTest -testname "shell_client" -vst -index "vst"
    registerTest -testname "shell_client" -http2 -index "http2"
    registerTest -testname "shell_client_aql" -index "http"
    registerTest -testname "shell_client_aql" -vst -index "vst"
    registerTest -testname "shell_client_aql" -http2 -index "http2"
    If ($ENTERPRISEEDITION -eq "On") { registerTest -testname "shell_client_aql" -encrypt -index "encrypt" }
    registerTest -testname "shell_fuzzer"
    registerTest -testname "shell_replication" -weight 2
    registerTest -testname "BackupAuthNoSysTests"
    registerTest -testname "BackupAuthSysTests"
    registerTest -testname "BackupNoAuthNoSysTests"
    registerTest -testname "BackupNoAuthSysTests"
    registerTest -testname "active_failover"
    registerTest -testname "agency" -weight 2 -sniff true
    registerTest -testname "agency-restart"
    registerTest -testname "arangobench"
    registerTest -testname "arangosh"
    registerTest -testname "audit"
    registerTest -testname "authentication"
    registerTest -testname "authentication_parameters"
    registerTest -testname "authentication_server"
    registerTest -testname "catch"
    registerTest -testname "config"
    registerTest -testname "dfdb"
    registerTest -testname "dump"
    registerTest -testname "dump_authentication"
    registerTest -testname "dump_encrypted"
    registerTest -testname "dump_jwt"
    registerTest -testname "dump_maskings"
    registerTest -testname "dump_multiple"
    registerTest -testname "dump_no_envelope"
    registerTest -testname "dump_encrypted"
    registerTest -testname "dump_with_crashes"
    registerTest -testname "endpoints"
    registerTest -testname "export"
    registerTest -testname "foxx_manager"
    registerTest -testname "fuerte"
    registerTest -testname "communication"
    registerTest -testname "communication_ssl"
    registerTest -testname "http_replication" -weight 2
    registerTest -testname "importing"
    registerTest -testname "queryCacheAuthorization"
    registerTest -testname "readOnly"
    registerTest -testname "upgrade"
    registerTest -testname "version"
    registerTest -testname "audit_client"
    registerTest -testname "audit_server"
    registerTest -testname "server_secrets"
    registerTest -testname "permissions"
    registerTest -testname "server_permissions"
    registerTest -testname "server_parameters"
    registerTest -testname "paths_server"
    # registerTest -testname "replication2_client"
    # registerTest -testname "replication2_server"
    # Note that we intentionally do not register the hot_backup test here,
    # since it is currently not supported on Windows. The reason is that
    # the testing framework does not support automatic restarts of instances
    # and hot_backup currently needs a server restart on a restore operation
    # on Windows. On Linux and Mac we use an exec operation for this to
    # restart without changing the PID, which is not possible on Windows.
    # registerTest -testname "hot_backup"
    comm
}

Function global:registerClusterTests()
{
    noteStartAndRepoState
    Write-Host "Registering tests..."

    $global:TESTSUITE_TIMEOUT = 18000

    registerTest -cluster $true -testname "load_balancing"
    registerTest -cluster $true -testname "load_balancing_auth"
    registerTest -cluster $true -testname "resilience_move"
    registerTest -cluster $true -testname "resilience_move_view"
    registerTest -cluster $true -testname "resilience_repair"
    registerTest -cluster $true -testname "resilience_failover"
    registerTest -cluster $true -testname "resilience_failover_failure"
    registerTest -cluster $true -testname "resilience_failover_view"
    registerTest -cluster $true -testname "resilience_transactions"
    registerTest -cluster $true -testname "resilience_sharddist"
    registerTest -cluster $true -testname "resilience_analyzers"
    registerTest -cluster $true -testname "recovery_cluster" -index "0" -bucket "4/0" "arangosearch"
    registerTest -cluster $true -testname "recovery_cluster" -index "1" -bucket "4/1" "arangosearch"
    registerTest -cluster $true -testname "recovery_cluster" -index "2" -bucket "4/2" "arangosearch"
    registerTest -cluster $true -testname "recovery_cluster" -index "3" -bucket "4/3" "arangosearch"
    registerTest -cluster $true -testname "shell_api" -index "http" -sniff true
    registerTest -cluster $true -testname "shell_api" -index "https" -ssl -sniff true
    registerTest -cluster $true -testname "shell_client" -index "0" -bucket "4/0"
    registerTest -cluster $true -testname "shell_client" -index "1" -bucket "4/1"    
    registerTest -cluster $true -testname "shell_client" -index "2" -bucket "4/2"    
    registerTest -cluster $true -testname "shell_client" -index "3" -bucket "4/3"
    registerTest -cluster $true -testname "shell_server"
    registerTest -cluster $true -testname "restart"
    registerTest -cluster $true -testname "server_secrets"
    registerTest -cluster $true -testname "server_permissions"
    registerTest -cluster $true -testname "server_parameters"
    registerTest -cluster $true -testname "shell_server_aql" -index "0" -bucket "5/0" -moreParams "--extraArgs:log.level v8=trace"
    registerTest -cluster $true -testname "shell_server_aql" -index "1" -bucket "5/1"
    registerTest -cluster $true -testname "shell_server_aql" -index "2" -bucket "5/2"
    registerTest -cluster $true -testname "shell_server_aql" -index "3" -bucket "5/3"
    registerTest -cluster $true -testname "shell_server_aql" -index "4" -bucket "5/4"
    registerTest -cluster $true -testname "shell_client_aql"
    registerTest -cluster $true -testname "shell_fuzzer"
    registerTest -cluster $true -testname "communication"
    registerTest -cluster $true -testname "communication_ssl"
    registerTest -cluster $true -testname "dump"
    registerTest -cluster $true -testname "dump_jwt"
    registerTest -cluster $true -testname "dump_maskings"
    registerTest -cluster $true -testname "dump_multiple"
    registerTest -cluster $true -testname "dump_no_envelope"
    registerTest -cluster $true -testname "dump_encrypted"
    registerTest -cluster $true -testname "dump_with_crashes"
    registerTest -cluster $true -testname "export"
    registerTest -cluster $true -testname "audit_client"
    registerTest -cluster $true -testname "audit_server"
    registerTest -cluster $true -testname "arangobench"
    registerTest -cluster $true -testname "chaos" -moreParams "--skipNightly false"
    registerTest -cluster $true -testname "wal_cleanup"
    registerTest -cluster $true -testname "replication2_client"
    registerTest -cluster $true -testname "replication2_server"
    # registerTest -cluster $true -testname "agency" -weight 2
    # Note that we intentionally do not register the hot_backup test here,
    # since it is currently not supported on Windows. The reason is that
    # the testing framework does not support automatic restarts of instances
    # and hot_backup currently needs a server restart on a restore operation
    # on Windows. On Linux and Mac we use an exec operation for this to
    # restart without changing the PID, which is not possible on Windows.
    # registerTest -cluster $true -testname "hot_backup"
    comm
}

runTests
