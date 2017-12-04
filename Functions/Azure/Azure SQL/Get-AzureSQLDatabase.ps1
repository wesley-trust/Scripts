<#

#Script name: Get-AzureSQLDatabase
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 2
#References:

.Synopsis
    A script that gets SQL databases on a specific server, excluding any specified pools.
.DESCRIPTION
    A script that gets SQL databases on a specific server, excluding any specified pools,
    when no SQL pools are specified, all databases on the server are returned (excluding master),
    includes error checking for whether the SQL server exists.
#>


function Get-AzureSQLDatabase() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subscription ID"
        )]
        [string]
        $SubscriptionID,    
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the resource group that all VMs belong to"
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
        $SQLPoolExclusion = $true,
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
            # Load functions
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\"
            . .\Connect-AzureRM.ps1
            
            # Connect to Azure
            Connect-AzureRM -SubscriptionID $SubscriptionID
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {
            # Get SQL Servers
            if ($ResourceGroupName){
                $SQLServers = Get-AzureRmSqlServer -ResourceGroupName $ResourceGroupName
            }
            else {
                $SQLServers = Get-AzureRmSqlServer
            }

            # If there are servers
            if ($SQLServers){
                
                # But no SQL Server is specified
                if (!$SQLServer){
                    Write-Host "`nAvailable SQL Servers:`n"
                    
                    # List servers
                    foreach ($SQLServer in $SQLServers) {
                        Write-Host $SQLServer.ServerName
                    }

                    # Prompt for SQL Server
                    while (!$SQLServer){
                        $SQLServer = Read-Host "Enter SQL Server"
                    } 
                }
            }
            else {
                $ErrorMessage = "No SQL Servers available in the current subscription"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
            
            # Check for valid SQL Server
            while ($SQLServers.ServerName -notcontains $SQLServer){
                $SQLServer = Read-Host "SQL Server is invalid or you do not have access, specify a new Server name"
            }

            # Update resource group name from SQL Server
            $ResourceGroupName = $SQLServer.ResourceGroupName

            # Get all databases from SQL server
            $SQLDatabases = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SQLServer

            # If SQL Pool exclusion is true
            if ($SQLPoolExclusion){

                # For each pool, exclude the SQL Pool databases
                foreach ($SQLPool in $SQLPools){
                    $SQLDatabases = $SQLDatabases | Where-Object {$_.elasticpoolname -ne $SQLPool}
                }
            }

            # Exclude master database
            $SQLDatabases = $SQLDatabases | Where-Object {$_.DatabaseName -notmatch "Master"}

            # If there are databases
            if ($SQLDatabases){
                
                # If email notification is enabled
                If ($Email) {

                    # Set subject and body
                    $Subject =  "Databases not in an Elastic Pool on SQL Server $SQLServer"
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
                Write-Output "No databases found."
            }
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    End {

    }
}