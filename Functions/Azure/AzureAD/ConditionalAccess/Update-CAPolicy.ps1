<#
.Synopsis
    Update Conditional Access policies deployed in the Azure AD tenant
.Description
    This function updates the Conditional Access policies in Azure AD using the Microsoft Graph API.
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
    Update-CAPolicy @Parameters -RemoveAllExistingPolicies
    $ConditionalAccessPolicies | Update-CAPolicy -AccessToken $AccessToken
#>

function Update-CAPolicy {
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
            HelpMessage = "The Conditional Access policies to remove, a policy must have a valid id"
        )]
        [Alias('ConditionalAccessPolicy', 'PolicyDefinition')]
        [pscustomobject]$ConditionalAccessPolicies,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Override the policy state when value specified"
        )]
        [ValidateSet("enabled", "enabledForReportingButNotEnforced", "disabled", "")]
        [AllowNull()]
        [String]
        $PolicyState
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
            $Method = "Patch"
            $ApiVersion = "beta" # If preview features are in use, the "beta" API must be used
            $Uri = "identity/conditionalAccess/policies"
            $CleanUpProperties = (
                "createdDateTime",
                "modifiedDateTime",
                "REF",
                "VER",
                "ENV"
            )

            # Force TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # Output current activity
            Write-Host "Updating Conditional Access Policies"
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

                # If there are policies to update, foreach policy with a policy id
                if ($ConditionalAccessPolicies) {
                    
                    foreach ($Policy in $ConditionalAccessPolicies) {
                        
                        # Update policy ID, and if exists continue
                        $PolicyID = $Policy.id
                        if ($PolicyID) {

                            # Remove properties that are not valid for when updating policies
                            foreach ($Property in $CleanUpProperties) {
                                $Policy.PSObject.Properties.Remove("$Property")
                            }

                            # Override policy state 
                            if ($PolicyState) {
                                $Policy.state = "$PolicyState"
                            }
                            
                            # Convert policy object to JSON
                            $Policy = $Policy | ConvertTo-Json -Depth 10
                            
                            # Create policy, with one second intervals to prevent throttling
                            Write-Host "Processing Policy ID: $PolicyID"
                            Start-Sleep -Seconds 1
                            $AccessToken | Invoke-MSGraphQuery `
                                -Method $Method `
                                -Uri "$ApiVersion/$Uri/$PolicyID" `
                                -Body $Policy `
                            | Out-Null
                        }
                        else {
                            $ErrorMessage = "The Conditional Access policy does not contain an id, so cannot be updated"
                            Write-Error $ErrorMessage
                        }
                    }
                }
                else {
                    $ErrorMessage = "There are no Conditional Access policies to be updated"
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
