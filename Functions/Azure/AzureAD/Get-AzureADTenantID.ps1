<#
#Script name: Get Azure AD Tenant ID
#Creator: Wesley Trust
#Date: 2019-03-14
#Revision: 1
#References: 

.Synopsis
    Function to query Microsoft Login for the Azure AD tenant ID via OpenID.
.Description
    
.Example
    
#>
function Get-AzureADTenantID {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the Azure AD domain to query for a valid tenant and return ID"
        )]
        [string]
        $AzureADDomain
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
            # Variables
            $MicrosoftLogin = "https://login.microsoftonline.com/"
            $OpenIDConfig = "/.well-known/openid-configuration"
            $QueryURL = "$MicrosoftLogin$AzureADDomain$OpenIDConfig"
            
            # Query for valid tenant, catching terminating error, checking for correct GUID length
            try {
                $WebRequest = Invoke-WebRequest $QueryURL
                if ($WebRequest.StatusCode -eq "200") {
                    $TenantId = $WebRequest.Content.Split("/")[3]
                    if ($TenantID.Length -eq 36) {
                        $TenantDiscovered = $true
                    }
                    else {
                        $TenantId = $null
                        $ErrorMessage = "Query has not returned a valid 36 character GUID."
                        Write-Error $ErrorMessage
                        throw $ErrorMessage
                    }
                }
            }
            catch {
                $TenantDiscovered = $false
            }

            # Build object
            $TenantObject = [PSCustomObject]@{
                Domain           = $AzureADDomain
                TenantDiscovered = $TenantDiscovered
                TenantID         = $TenantId
            }
            return $TenantObject
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {
        try {

        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
}