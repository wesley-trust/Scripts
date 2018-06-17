<#

#Script name: Get-AzureSQLDatabase
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 2
#References:

.Synopsis
    A function that gets all SQL servers in a subscription, or within a group, and displays a list if needed.
.DESCRIPTION

#>

function Get-AzureSQLServer() {
    [CmdletBinding()]
    Param(
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
                        $SQLServers | Select-Object ServerName | Out-Host -Paging

                        # Prompt for SQL Server
                        while (!$SQLServer){
                            $SQLServer = Read-Host "Enter SQL Server"
                            while ($SQLServers.ServerName -notcontains $SQLServer){
                                $SQLServer = Read-Host "Enter valid SQL Server name"
                            }
                        }
                    }
                }
            }
            else {
                $ErrorMessage = "No SQL Servers available in the current subscription"
                Write-Error $ErrorMessage
                throw $ErrorMessage
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
        try {
            
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
}