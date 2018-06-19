<#
#Script name: Test active connection to Azure
#Creator: Wesley Trust
#Date: 2018-04-14
#Revision: 1
#References: 

.Synopsis
    Function that checks for active connection to Azure
.Description
    Including whether correct credentials are in use and access to specified subscription/tenant
.Example
    Test-AzureConnection -Credential $Credential
.Example

.Example

#>
function Test-AzureConnection() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
    
    Process {
        try {

            # Check if module is installed
            Write-Host "`nPerforming Connection Check"
            Write-Host "`nRequired Connection(s): Azure RM"

            $ObjectProperties = @{
                Connection = "Azure RM"
            }
            
            # Check to see if there is an active connection to Azure
            $AzureContext = Get-AzureRmContext

            # If there is a connection
            if ($AzureContext.account.id) {
                $ObjectProperties += @{
                    ActiveConnection = $true
                }
                
                # If there is a credential, check to see if these match
                if ($Credential) {
                    if ($Credential.UserName -ne $AzureContext.account.id) {
                        $ObjectProperties += @{
                            CredentialCheck = $false
                            Reauthenticate  = $true
                        }
                    }
                }
            }
            else {
                $ObjectProperties += @{
                    ActiveConnection = $false
                }
            }
            New-Object -TypeName psobject -Property $ObjectProperties
        }
        Catch {
            Write-Error -Message $_.exception
        }
    }
    End {
        
    }
}