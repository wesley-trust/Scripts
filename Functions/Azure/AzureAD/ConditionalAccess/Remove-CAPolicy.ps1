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
.PARAMETER ConditionalAccessPolicies
    The Conditional Access policies to remove, a policy must have a valid id
.INPUTS
    None
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
    Remove-CAPolicy @Parameters -RemoveAllExistingPolicies
    Remove-CAPolicy -AccessToken $AccessToken -RemoveAllExistingPolicies
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
        [switch]$ExcludePreviewFeatures,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            ValueFromPipeLine = $true,
            HelpMessage = "The Conditional Access policies to remove, this must contain valid id(s)"
        )]
        [Alias("id", "PolicyID")]
        [string[]]$PolicyIDs
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

            # Output current activity
            Write-Host "Removing Conditional Access Policies"

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

                # Build Parameters
                $Parameters = @{}
                $Parameters = @{
                    AccessToken = $AccessToken
                }
                if ($ExcludePreviewFeatures) {
                    $Parameters += @{
                        ExcludePreviewFeatures = $true
                    }
                }

                # Get all existing policies to be removed if specified
                if ($RemoveAllExistingPolicies) {
                    $ConditionalAccessPolicies = Get-CAPolicy @Parameters -ExcludeTagEvaluation

                        $ConditionalAccessPolicies = Get-CAPolicy -AccessToken $AccessToken -ExcludeTagEvaluation
                    }
                }

                # If there are policies to be removed, remove each of them
                if ($ConditionalAccessPolicies) {
                    
                    foreach ($Policy in $ConditionalAccessPolicies) {
                        
                        # Update policy ID, and if exists continue
                        $PolicyID = $Policy.id
                        if ($PolicyID) {
                            Write-Host "Processing Policy ID: $PolicyID"
                            Start-Sleep -Seconds 1
                            $AccessToken | Invoke-MSGraphQuery `
                                -Method $Method `
                                -Uri "$ApiVersion/$Uri/$PolicyID" `
                            | Out-Null
                        }
                        else {
                            $ErrorMessage = "The Conditional Access policy does not contain an id, so cannot be removed"
                            Write-Error $ErrorMessage
                        }
                    }
                }
                else {
                    $ErrorMessage = "There are no Conditional Access policies to be removed"
                    Write-Error $ErrorMessage
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
