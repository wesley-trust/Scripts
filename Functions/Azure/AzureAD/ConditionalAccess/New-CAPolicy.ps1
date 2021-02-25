<#
.Synopsis
    Create new Conditional Access policies in the Azure AD tenant
.Description
    This function creates the Conditional Access policies in Azure AD using the Microsoft Graph API.
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
    Specify the Conditional Access policies to create
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
    New-CAPolicy @Parameters -CondionalAccessPolicies $CondionalAccessPolicies
    $CondionalAccessPolicies | New-CAPolicy -AccessToken $AccessToken
#>

function New-CAPolicy {
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
            HelpMessage = "Specify the Conditional Access policies to create"
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
                "$FunctionLocation\GraphAPI\Invoke-MSGraphQuery.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

            # Variables
            $Method = "Post"
            $ApiVersion = "beta" # If preview features are in use, the "beta" API must be used
            $Uri = "identity/conditionalAccess/policies"
            $CleanUpProperties = (
                "id",
                "createdDateTime",
                "modifiedDateTime",
                "REF",
                "VER",
                "ENV"
            )
            $Counter = 1

            # Force TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # Output current activity
            Write-Host "Creating Conditional Access Policies"

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

                # If there are policies to deploy, for each
                if ($ConditionalAccessPolicies) {
                    
                    foreach ($Policy in $ConditionalAccessPolicies) {

                        # Remove properties that are not valid for when creating new policies
                        foreach ($Property in $CleanUpProperties) {
                            $Policy.PSObject.Properties.Remove("$Property")
                        }
                        
                        # Update displayname variable prior to object converstion to JSON
                        $PolicyDisplayName = $Policy.displayName

                        # Override policy state 
                        if ($PolicyState) {
                            $Policy.state = "$PolicyState"
                        }

                        # Convert policy object to JSON
                        $Policy = $Policy | ConvertTo-Json -Depth 10

                        # Output progress
                        if ($ConditionalAccessPolicies.count -gt 1) {
                            Write-Host "Processing Policy $Counter of $($ConditionalAccessPolicies.count) with Display Name: $PolicyDisplayName"
                        
                            # Create progress bar
                            $PercentComplete = (($counter / $ConditionalAccessPolicies.count) * 100)
                            Write-Progress -Activity "Creating Conditional Access Policy" `
                                -PercentComplete $PercentComplete `
                                -CurrentOperation $PolicyDisplayName
                        }
                        else {
                            Write-Host "Processing Policy $Counter with Display Name: $PolicyDisplayName"
                            
                        }
                        
                        # Increment counter
                        $counter++

                        # Create policy, with one second intervals to prevent throttling
                        Start-Sleep -Seconds 1
                        $AccessToken | Invoke-MSGraphQuery `
                            -Method $Method `
                            -Uri $ApiVersion/$Uri `
                            -Body $Policy `
                        | Out-Null
                    }
                }
                else {
                    $ErrorMessage = "There are no Conditional Access policies to be created"
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