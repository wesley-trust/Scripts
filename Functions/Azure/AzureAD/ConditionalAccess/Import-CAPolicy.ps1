<#
.Synopsis
    Import all Conditional Access policies from JSON definition
.Description
    This function imports the Conditional Access policies from JSON using the Microsoft Graph API.
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
.PARAMETER FilePath
    The file path to the JSON file that will be imported
.PARAMETER PolicyState
    Modify the policy state when imported, when not specified the policy will maintain state
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
                FilePath = ""
    }
    Import-CAPolicy @Parameters
    Import-CAPolicy -AccessToken $AccessToken -FilePath ""
#>

function Import-CAPolicy {
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
            HelpMessage = "The file path to the JSON file(s) that will be imported"
        )]
        [string[]]$FilePath,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The directory path(s) of which all JSON file(s) will be imported"
        )]
        [string[]]$DirectoryPath,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "If a policy is enabled, modify the policy state when imported if specified"
        )]
        [ValidateSet("enabled", "enabledForReportingButNotEnforced", "disabled", "")]
        [AllowNull()]
        [String]
        $PolicyState,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether to replace existing policies deployed in the tenant, where the IDs match"
        )]
        [switch]
        $UpdateExistingPolicies,
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
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Remove-CAPolicy.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\New-CAPolicy.ps1"
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Update-CAPolicy.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

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
                
                # For each directory, get the file path of all JSON files within the directory
                if ($DirectoryPath){
                    $FilePath = foreach ($Directory in $DirectoryPath){
                        (Get-ChildItem -Path $Directory -Filter "*.json").FullName
                    }
                }

                # Import policies from JSON file
                $ConditionalAccessPolicies = foreach ($File in $FilePath){
                    Get-Content -Raw -Path $File
                }
                
                if ($ConditionalAccessPolicies) {
                    $ConditionalAccessPolicies = $ConditionalAccessPolicies | ConvertFrom-Json

                    # Output current action
                    Write-Host "Importing Conditional Access Policies (Count: $($ConditionalAccessPolicies.count))"

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

                    # Remove all existing policies if specified
                    if ($RemoveAllExistingPolicies) {
                        Remove-CAPolicy @Parameters -RemoveAllExistingPolicies
                    }
                    elseif ($UpdateExistingPolicies) {

                        # Update parameters
                        if ($PolicyState) {
                            $Parameters += @{
                                PolicyState = $PolicyState
                            }
                        }
                        
                        # Filter for policies that contain an id, which is required to update a policy
                        $UpdatePolicies = $ConditionalAccessPolicies | Where-Object id -NE $null

                        Update-CAPolicy @Parameters -ConditionalAccessPolicies $UpdatePolicies

                        # Filter for policies that do not contain an id, and so are policies that should be created
                        $CreatePolicies = $ConditionalAccessPolicies | Where-Object id -EQ $null
                    }

                    # If policies should not be updated, change the variable to create all the policies
                    # If any of the policies contain existing ids, these are not validated when creating policies, so duplicates may be created
                    if (!$UpdateExistingPolicies) {
                        $CreatePolicies = $ConditionalAccessPolicies

                        # Update parameters
                        if ($PolicyState) {
                            $Parameters += @{
                                PolicyState = $PolicyState
                            }
                        }
                    }

                    # If there are new policies to be created, create them, passing through the policy state
                    if ($CreatePolicies) {
                        New-CAPolicy @Parameters -ConditionalAccessPolicies $CreatePolicies
                    }
                }
                else {
                    $ErrorMessage = "No Conditional Access policies to be imported, check the import file"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
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