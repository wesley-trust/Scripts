<#
#Script name: Connect AzureAD Automation
#Creator: Wesley Trust
#Date: 2018-09-28
#Revision: 1
#References: 

.Synopsis
    Function that connects to an AzureAD tenant via an Azure Automation Service Principal.
.Description

.Example
    Connect-AzureRMAutomation -SubscriptionID $SubscriptionID
.Example
    

#>
function Connect-AzureADAutomation() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify Connection Name"
        )]
        [string]
        $connectionName = "AzureRunAsConnection"
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
                    TenantId = $servicePrincipalConnection.TenantId
                    ApplicationId = $servicePrincipalConnection.ApplicationId
                    CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
                }

                "`nAuthenticating to Azure AD with Azure Automation Service Principal`n"
                $AzureADConnection = Connect-AzureAD @CustomParameters
                if ($AzureADConnection){
                    return $AzureADConnection
                }
                else {
                    $ErrorMessage = "Unable to authenticate with Azure AD."
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