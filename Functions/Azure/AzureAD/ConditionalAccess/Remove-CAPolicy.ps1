<#
.Synopsis
    Remove Conditional Access policies deployed in the Azure AD tenant
.Description
    This function gets the Conditional Access policies from Azure AD using the Microsoft Graph API.
    The following Microsoft Graph API permissions are required for the service principal used for authentication:
        Policy.ReadWrite.ConditionalAccess
        Policy.Read.All
        Directory.Read.All
        Agreement.Read.All
        Application.Read.All
.PARAMETER ClientID
    Client ID for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER ClientSecret
    Client secret for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER TenantName
    The initial domain (onmicrosoft.com) of the tenant
.PARAMETER AccessToken
    The access token, obtained from executing Get-MSGraphAccessToken
.PARAMETER RemoveAllExistingPolicies
    Specify whether all existing policies deployed in the tenant will be removed
.PARAMETER ExcludePreviewFeatures
    Specify whether to exclude features in preview, a production API version will then be used instead
.INPUTS
    JSON file with all Conditional Access policies
.OUTPUTS
    None
.NOTES
    Reference: https://danielchronlund.com/2018/11/19/fetch-data-from-microsoft-graph-with-powershell-paging-support/
.Example
    $Parameters = @{
                ClientID = ""
                ClientSecret = ""
                TenantDomain = ""
    }
    Get-CAPolicy @Parameters
    $AccessToken | Get-CAPolicy
#>

function Remove-CAPolicy {
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
        [string]$TenantDomain,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The access token, obtained from executing Get-MSGraphAccessToken"
        )]
        [string]$AccessToken,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether all existing policies deployed in the tenant will be removed"
        )]
        [switch]
        $RemoveAllExistingPolicies,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether to exclude features in preview, a production API version will then be used instead"
        )]
        [switch]$ExcludePreviewFeatures
    )
    Begin {
        try {
            # Function definitions
            $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
            $Functions = @(
                "$FunctionLocation\GraphAPI\Get-MSGraphAccessToken.ps1",
                "$FunctionLocation\GraphAPI\Invoke-MSGraphQuery.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Get-CAPolicy.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

            # Variables
            $Method = "Delete"
            $ApiVersion = "beta" # If preview features are in use, the "beta" API must be used
            $Uri = "identity/conditionalAccess/policies"

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

            # If there is no access token, obtain one
            if (!$AccessToken) {
                $AccessToken = Get-MSGraphAccessToken `
                    -ClientID $ClientID `
                    -ClientSecret $ClientSecret `
                    -TenantDomain $TenantDomain
            }
            if ($AccessToken) {

                # Change the API version if features in preview are to be excluded
                if ($ExcludePreviewFeatures) {
                    $ApiVersion = "v1.0"
                }

                # Remove all existing policies if specified, and policies exist
                if ($RemoveAllExistingPolicies) {
                    if ($ExcludePreviewFeatures) {
                        $ExistingPolicies = Get-CAPolicy -AccessToken $AccessToken -ExcludeTagging -ExcludePreviewFeatures
                    }
                    else {
                        $ExistingPolicies = Get-CAPolicy -AccessToken $AccessToken -ExcludeTagging 
                    }
                    if ($ExistingPolicies.value) {
                        foreach ($Policy in $ExistingPolicies) {
                            Start-Sleep -Seconds 1
                            $AccessToken | Invoke-MSGraphQuery `
                                -Method $Method `
                                -Uri "$ApiVersion/$Uri/$($Policy.id)" `
                            | Out-Null
                        }
                    }
                }
            }
            else {
                $ErrorMessage = "No access token specified, obtain an access token object from Get-MSGraphAccessToken"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    End {
        
    }
}
