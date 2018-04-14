<#
#Script name: Connect AzureRM Automation
#Creator: Wesley Trust
#Date: 2018-04-14
#Revision: 1
#References: 

.Synopsis
    Function that connects to an AzureRM subscription via an Azure Automation Service Principal.
.Description

.Example
    Connect-AzureRMAutomation -SubscriptionID $SubscriptionID
.Example
    

#>
function Connect-AzureRMAutomation() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify Connection Name"
        )]
        [string]
        $connectionName = "AzureRunAsConnection",
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify SubscriptionId"
        )]
        [string]
        $SubscriptionId
    )

    Begin {
        try {
            # Get the service principal of the connection
            $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName
        }
        
        # Catch when Azure Automation command is not found
        catch [System.Management.Automation.CommandNotFoundException] {
            $ErrorMessage = "Function is not being executed in Azure Automation"
            throw $ErrorMessage
        }
        
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # If there is a service principal
            if ($ServicePrincipalConnection){
                # Create hash table of custom parameters
                $CustomParameters = @{}
                $CustomParameters += @{
                    ServicePrincipal = $True
                    TenantId = $servicePrincipalConnection.TenantId
                    ApplicationId = $servicePrincipalConnection.ApplicationId
                    CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
                }
                if ($SubscriptionId){
                    $CustomParameters += @{
                        SubscriptionId = $SubscriptionId
                    }
                }

                "`nAuthenticating with Azure Automation`n"
                $AzureConnection = Connect-AzureRmAccount @CustomParameters
                if ($AzureConnection){
                    $AzureContext = Get-AzureRmContext
                    return $AzureContext
                }
                else {
                    $ErrorMessage = "Unable to authenticate with Azure."
                    throw $ErrorMessage
                }
            }
            else {
                $ErrorMessage = "Connection $ConnectionName not found."
                throw $ErrorMessage
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}