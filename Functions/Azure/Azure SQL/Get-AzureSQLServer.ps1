<#

#Script name: Get-AzureSQLDatabase
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 1
#References:

.Synopsis
    A function that gets all SQL servers in a subscription, or within a group, and displays a list if needed.
.DESCRIPTION

#>


function Get-AzureSQLServer() {
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
        $SQLServer
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

                    # If there is more than one server
                    if ($SQLServers.count -gt "1"){
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

            # Get SQL Server object
            $SQLServer = $SQLServers | Where-Object ServerName -eq $SQLServer
            return $SQLServer
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    End {

    }
}