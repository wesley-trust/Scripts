<#

#Script name: Get-AzureSQLDatabase
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 3
#References:

.Synopsis
    A script that gets SQL databases on a specific server, including any specified pools.
.DESCRIPTION
    A script that gets SQL databases on a specific server, including any specified pools,
    when no SQL pools are specified, all databases on the server are returned (excluding master),
    includes error checking for whether the SQL server exists.
#>
function Get-AzureSQLDatabaseInsidePool {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the resource group that SQL server belong to"
        )]
        [string]
        $ResourceGroupName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the SQL Server to check"
        )]
        [string]
        $SQLServer,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the SQL Elastic Pools to check (if any)"
        )]
        [string[]]
        $SQLPools,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to exclude database from specified pools"
        )]
        [bool]
        $SQLPoolInclusion = $true,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to email results"
        )]
        [bool]
        $Email = $false,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the email server username"
        )]
        [string]
        $EmailUsername,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the email server password"
        )]
        [string]
        $PlainTextPass,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the SMTP Server"
        )]
        [string]
        $SMTPServer,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the recipient email address"
        )]
        [string]
        $ToAddress,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the sender email address"
        )]
        [string]
        $FromAddress
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {

            # Get all databases from SQL server
            $SQLDatabases = Get-AzureRmSqlDatabase `
                -ResourceGroupName $ResourceGroupName `
                -ServerName $SQLServer

            # If SQL Pool inclusion is true
            if ($SQLPoolInclusion){
    
                # Set databases variable to only contain databases that are within a pool in the SQL pools array
                $SQLDatabases = $SQLDatabases | Where-Object {$SQLPools -contains $_.elasticpoolname}
            }

            # Exclude master database
            $SQLDatabases = $SQLDatabases | Where-Object {$_.DatabaseName -notmatch "Master"}

            # If there are databases
            if ($SQLDatabases){
                
                # If email notification is enabled
                If ($Email) {

                    # Set subject and body
                    $Subject =  "Databases not in an Elastic Pool on SQL Server "+$SQLServer.Servername
                    $Body = $SQLDatabases.DatabaseName
                    $Body = [string]::join("<br/>",$body)

                    
                    # Build Email Credential
                    $EmailPassword = ConvertTo-SecureString $PlainTextPass -AsPlainText -Force
                    $EmailCredential = New-Object System.Management.Automation.PSCredential ($EmailUsername, $EmailPassword)
                    
                    # Send email
                    Send-MailMessage `
                        -Credential $EmailCredential `
                        -SmtpServer $SMTPServer `
                        -To $ToAddress `
                        -From $FromAddress `
                        -Subject $Subject `
                        -BodyAsHtml `
                        -Body $Body
                }
                else {
                    # Display database names
                    $SQLDatabases.DatabaseName
                }
            }
            Else {
                Write-Output "No databases found"
            }
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    End {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
}