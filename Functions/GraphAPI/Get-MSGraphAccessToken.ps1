<#
.Synopsis
    Function to connect to Microsoft Graph using a service principal and obtain and an access token
.Description
    Connects to Microsoft Graph and returns an access token object, accepts pipeline input for multiple token requests
.PARAMETER ClientID
    Client ID for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER ClientSecret
    Client secret for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER TenantName
    The initial domain (onmicrosoft.com) of the tenant
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Reference: https://danielchronlund.com/2018/11/19/fetch-data-from-microsoft-graph-with-powershell-paging-support/
.Example
    $MSGraphAccessToken = Get-MSGraphAccessToken -ClientID "" -ClientSecret "" -TenantDomain ""
    $MSGraphAccessToken = $ServicePrincipalObject | Get-MSGraphAccessToken
#>

function Get-MSGraphAccessToken {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Client ID for the Azure AD service principal with Conditional Access Graph permissions"
        )]
        [string]$ClientID,
        
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Client secret for the Azure AD service principal with Conditional Access Graph permissions"
        )]
        [string]$ClientSecret,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The initial domain (onmicrosoft.com) of the tenant"
        )]
        [string]$TenantDomain
    )
    Begin {
        try {
            # Variables
            $SigninUrl = "https://login.microsoft.com"
            $ResourceUrl = "https://graph.microsoft.com"
                        
            # Force TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {
            # Compose and invoke REST request
            $Body = @{
                grant_type    = "client_credentials";
                resource      = $ResourceUrl;
                client_id     = $ClientID;
                client_secret = $ClientSecret 
            }
            $OAuth2 = Invoke-RestMethod -Method Post -Uri $SigninUrl/$TenantDomain/oauth2/token?api-version=1.0 -Body $Body

            # If an access token is returned, build and return an access token object
            if ($OAuth2.access_token) {
                $ObjectProperties = [pscustomobject]@{
                    TenantDomain = $TenantDomain
                    ClientID     = $ClientID
                    AccessToken  = $OAuth2.access_token
                }
                $ObjectProperties
            }
            else {
                $ErrorMessage = "Unable to obtain an access token for $TenantDomain but an exception has not occurred"
                Write-Error $ErrorMessage
            }
        }
        catch {
            $ErrorMessage = "Unable to obtain an access token for $TenantDomain, an exception has occurred which may have more information"
            Write-Error $ErrorMessage
            Write-Error -Message $_.Exception
        }
    }
    End {
        
    }
}