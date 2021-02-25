<#
.Synopsis
    Get Conditional Access policies deployed in the Azure AD tenant
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
.PARAMETER ExcludePreviewFeatures
    Specify whether to exclude features in preview, a production API version will then be used instead
.PARAMETER ExcludeTagEvaluation
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

function Get-CAPolicy {
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
            HelpMessage = "Specify whether to exclude tag processing of policies"
        )]
        [switch]$ExcludeTagEvaluation,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            ValueFromPipeLine = $true,
            HelpMessage = "The Conditional Access policies to get, this must contain valid id(s)"
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
                "$FunctionLocation\GraphAPI\Invoke-MSGraphQuery.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

            # Variables
            $Method = "Get"
            $ApiVersion = "beta" # If preview features are in use, the "beta" API must be used
            $Uri = "identity/conditionalAccess/policies"
            $MajorDelimiter = ";"
            $MinorDelimiter = "-"
            $Tags = @("REF", "VER", "ENV")
            $Counter = 1

            # Force TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # Output current activity
            Write-Host "Getting Conditional Access Policies"

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
                
                # If specific policies are specified, get each, otherwise, get all policies
                if ($PolicyIDs) {
                    $ConditionalAccessPolicies = foreach ($PolicyID in $PolicyIDs) {
                        
                        # Output progress
                        if ($PolicyIDs.count -gt 1) {
                            Write-Host "Processing Policy $Counter of $($PolicyIDs.count) with ID: $PolicyID"
                                                
                            # Create progress bar
                            $PercentComplete = (($counter / $PolicyIDs.count) * 100)
                            Write-Progress -Activity "Getting Conditional Access Policy" `
                                -PercentComplete $PercentComplete `
                                -CurrentOperation $PolicyDisplayName
                        }
                        else {
                            Write-Host "Processing Policy $Counter with ID: $PolicyID"
                        }

                        # Increment counter
                        $counter++

                        # Get policy
                        $AccessToken | Invoke-MSGraphQuery `
                            -Method $Method `
                            -Uri $ApiVersion/$Uri/$PolicyID
                    }
                }
                else {
                    $ConditionalAccessPolicies = $AccessToken | Invoke-MSGraphQuery `
                        -Method $Method `
                        -Uri $ApiVersion/$Uri
                }

                # If there are policies, check whether policy tagging should be performed
                if ($ConditionalAccessPolicies.value) {
                    if ($ExcludeTagEvaluation) {
                        $ConditionalAccessPolicies
                    }
                    else {
                        
                        # Get policy properties
                        $PolicyProperties = ($ConditionalAccessPolicies | Get-Member -MemberType NoteProperty).name

                        foreach ($Policy in $ConditionalAccessPolicies) {

                            # Split out policy information by defined delimeter(s) and tag(s)
                            $PolicyDisplayNameSplit = ($Policy.displayName.split($MajorDelimiter)).Split($MinorDelimiter)
                            $ConditionalAccessPolicy = [ordered]@{}
                            foreach ($Tag in $Tags) {

                                # If the tag exists, get the index, increment by one to obtain the tag's value index, then add value to hashtable
                                if ($PolicyDisplayNameSplit -contains $Tag) {
                                    $TagIndex = $PolicyDisplayNameSplit.IndexOf($Tag)
                                    $TagValueIndex = $TagIndex + 1
                                    $TagValue = $PolicyDisplayNameSplit[$TagValueIndex]
                                    $ConditionalAccessPolicy.Add($Tag, $TagValue)
                                }
                                else {
                                    $ConditionalAccessPolicy.Add($Tag, $null)
                                }
                            }
                            
                            # Append all Conditional Access properties and return object
                            foreach ($Property in $PolicyProperties) {
                                $ConditionalAccessPolicy.Add("$Property", $Policy.$Property)
                            }

                            [pscustomobject]$ConditionalAccessPolicy
                        }
                    }
                }
                else {
                    $ErrorMessage = "No Conditional Access policies exist in Azure AD"
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
