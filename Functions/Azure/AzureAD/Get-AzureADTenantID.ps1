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
            HelpMessage = "Specify the Azure AD domain to query"
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
            
            # Query
            $WebRequest = Invoke-WebRequest $QueryURL

            # Check if query was successful
            if ($WebRequest.StatusCode -eq "200"){
                $TenantId = $WebRequest.Content.Split("/")[3]
            }
            else {
                $ErrorMessage = "No Azure AD tenant for $AzureADDomain"
                Write-Error $ErrorMessage
            }

            return $TenantId
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