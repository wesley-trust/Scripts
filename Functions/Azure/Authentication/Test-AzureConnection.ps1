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
            Mandatory=$false,
            HelpMessage="Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential
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
            # Check to see if there is an active connection to Azure
            $AzureContext = Get-AzureRmContext

            # If there is a connection
            if ($AzureContext.account.id){
                $ActiveAccountID = $AzureContext.Account.Id
                Write-Host "`nActive Azure Connection for $ActiveAccountID`n"
                $ActiveConnection = $True
                # If there is a credential, check to see if these match
                if ($Credential){
                    if ($Credential.UserName -ne $ActiveAccountID){
                        Write-Host "`nAccount credentials do not match active account, reauthenticating`n"
                        $Reauthenticate = $true
                    }
                }
            }
            $Properties = @{
                ActiveConnection = $ActiveConnection
                ReAuthenticate = $ReAuthenticate
            }
            return $Properties
        }
        Catch {
<#             Write-Error -Message $_.exception
            throw $_.exception #>
        }
    }
    End {
        
    }
}