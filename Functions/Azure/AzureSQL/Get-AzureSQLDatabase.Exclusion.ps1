<#

#Script name: Get-AzureSQLDatabase
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 3
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
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID

            # Update subscription Id from Azure Connection
            $SubscriptionID = $AzureConnection.Subscription.id
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {
            # Load functions
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Azure SQL"
            . Get-AzureSQLServer.ps1
            
            # Get SQL Server
            $SQLServer = Get-AzureSQLServer `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $ResourceGroupName `
                -SQLServer $SQLServer
            
            if (!$SQLServer){
                $ErrorMessage = "No SQL Server returned."
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # Get all databases from SQL server
            $SQLDatabases = Get-AzureRmSqlDatabase `
                -ResourceGroupName $SQLServer.ResourceGroupName `
                -ServerName $SQLServer.ServerName

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