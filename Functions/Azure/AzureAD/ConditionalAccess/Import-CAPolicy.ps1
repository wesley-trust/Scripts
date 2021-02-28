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
        [string[]]$Path,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Override the policy state when imported"
        )]
        [ValidateSet("enabled", "enabledForReportingButNotEnforced", "disabled", "")]
        [AllowNull()]
        [String]
        $PolicyState,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether to update existing policies deployed in the tenant, where the IDs match"
        )]
        [switch]
        $UpdateExistingPolicies,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether existing policies deployed in the tenant will be removed, if not present in the import"
        )]
        [switch]
        $RemoveExistingPolicies,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether to exclude features in preview, a production API version will then be used instead"
        )]
        [switch]$ExcludePreviewFeatures,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "If there are no policies to import, forcibly remove any existing policies"
        )]
        [switch]$Force
    )
    Begin {
        try {
            # Function definitions
            $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
            $Functions = @(
                "$FunctionLocation\GraphAPI\Get-MSGraphAccessToken.ps1",
                "$FunctionLocation\GraphAPI\Invoke-MSGraphQuery.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Remove-CAPolicy.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Get-CAPolicy.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\New-CAPolicy.ps1"
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Edit-CAPolicy.ps1"
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

                # For each directory, get the file path of all JSON files within the directory
                if ($Path) {
                    $FilePath = foreach ($Directory in $Path) {
                        (Get-ChildItem -Path $Directory -Filter "*.json").FullName
                    }
                }

                # Import policies from JSON file
                $ConditionalAccessPolicies = foreach ($File in $FilePath) {
                    Get-Content -Raw -Path $File
                }

                # If a file has been imported, convert from JSON to an object for deployment
                if ($ConditionalAccessPolicies) {
                    $ConditionalAccessPolicies = $ConditionalAccessPolicies | ConvertFrom-Json
                    
                    # Output current action
                    Write-Host "Importing Conditional Access Policies (Count: $($ConditionalAccessPolicies.count))"

                    # Evaluate policies if parameters exist
                    if ($RemoveExistingPolicies -or $UpdateExistingPolicies) {

                        # Get existing policies for comparison
                        $ExistingPolicies = Get-CAPolicy @Parameters -ExcludeTagEvaluation

                        if ($ExistingPolicies) {

                            # Compare object on id and pass thru all objects, including those that exist and are to be imported
                            $PolicyComparison = Compare-Object `
                                -ReferenceObject $ExistingPolicies `
                                -DifferenceObject $ConditionalAccessPolicies `
                                -Property id `
                                -PassThru

                            # Filter for policies that should be removed, as they do not exist in the import
                            if ($RemoveExistingPolicies) {
                                $RemovePolicies = $PolicyComparison | Where-Object { $_.sideindicator -eq "<=" }

                                # If policies require removing, pass the ids
                                if ($RemovePolicies) {
                                    $PolicyIDs = $RemovePolicies.id
                                    Remove-CAPolicy @Parameters -PolicyIDs $PolicyIDs
                                }
                                else {
                                    $WarningMessage = "No policies will be removed, as none exist that are different to the import"
                                    Write-Warning $WarningMessage
                                }
                            }
                            if ($UpdateExistingPolicies) {

                                # Check whether the policies that could be updated have valid ids (so can be updated, ignore the rest)
                                $UpdatePolicies = foreach ($Policy in $ConditionalAccessPolicies) {
                                    if ($Policy.id -in $ExistingPolicies.id) {
                                        $Policy
                                    }
                                }

                                if ($UpdatePolicies) {
                                
                                    # Compare again, with all mandatory property elements for differences
                                    $PolicyPropertyComparison = Compare-Object `
                                        -ReferenceObject $ExistingPolicies `
                                        -DifferenceObject $UpdatePolicies `
                                        -Property id, displayName, state, sessionControls, conditions, grantControls

                                    $UpdatePolicies = $PolicyPropertyComparison | Where-Object { $_.sideindicator -eq "=>" }
                                }

                                # If policies require updating, pass the ids
                                if ($UpdatePolicies) {
                                    Edit-CAPolicy @Parameters -ConditionalAccessPolicies $UpdatePolicies -PolicyState $PolicyState
                                }
                                else {
                                    $WarningMessage = "No policies will be updated, as none exist that are different to the import"
                                    Write-Warning $WarningMessage
                                }
                            }

                            # Filter for policies that do not contain an id, and so are policies that should be created
                            $CreatePolicies = $PolicyComparison | Where-Object { $_.sideindicator -eq "=>" }
                        }
                    }

                    # If there are no existing policies, then create everything from the import
                    if (!$ExistingPolicies) {
                        $CreatePolicies = $ConditionalAccessPolicies
                    }

                    # If there are new policies to be created, create them, passing through the policy state
                    if ($CreatePolicies) {
                        New-CAPolicy @Parameters -ConditionalAccessPolicies $CreatePolicies -PolicyState $PolicyState
                    }
                    else {
                        $WarningMessage = "No policies will be created, as none exist that are different to the import"
                        Write-Warning $WarningMessage
                    }
                }
                else {
                    $WarningMessage = "No Conditional Access policies to be imported"
                    Write-Warning $WarningMessage
                    
                    # If there are no policies to be imported, specify whether all existing policies should be forcibly removed
                    if ($Force) {
                        Remove-CAPolicy @Parameters -RemoveAllExistingPolicies
                    }
                    else {
                        $WarningMessage = "To remove any existing policies use the switch -Force"
                        Write-Warning $WarningMessage
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