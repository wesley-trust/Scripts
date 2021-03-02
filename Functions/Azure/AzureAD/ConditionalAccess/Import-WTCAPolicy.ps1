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
    The access token, obtained from executing Get-WTGraphAccessToken
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

.Example
    $Parameters = @{
                ClientID = ""
                ClientSecret = ""
                TenantDomain = ""
                FilePath = ""
    }
    Import-WTCAPolicy.ps1 @Parameters
    Import-WTCAPolicy.ps1 -AccessToken $AccessToken -FilePath ""
#>

function Import-WTCAPolicy {
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
            HelpMessage = "The access token, obtained from executing Get-WTGraphAccessToken"
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
        [string]$Path,
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
                "$FunctionLocation\GraphAPI\Get-WTGraphAccessToken.ps1",
                "$FunctionLocation\GraphAPI\Invoke-WTGraphResponseTagging.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Remove-WTCAPolicy.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Get-WTCAPolicy.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\New-WTCAPolicy.ps1"
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\New-WTCAGroup.ps1"
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Edit-WTCAPolicy.ps1"
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Export-WTCAPolicy.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

            # Variables
            $Tags = @("REF", "ENV")
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
                $AccessToken = Get-WTGraphAccessToken `
                    -ClientID $ClientID `
                    -ClientSecret $ClientSecret `
                    -TenantDomain $TenantDomain
            }
            if ($AccessToken) {
                # Build Parameters
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
                        $ExistingPolicies = Get-WTCAPolicy @Parameters -ExcludeTagEvaluation

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
                                    Remove-WTCAPolicy @Parameters -PolicyIDs $PolicyIDs
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
                                    Edit-WTCAPolicy @Parameters -ConditionalAccessPolicies $UpdatePolicies -PolicyState $PolicyState
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
                        
                        # Remove existing tags, so these can be updated from the display name
                        foreach ($Tag in $Tags) {
                            $CreatePolicies | Foreach-Object {
                                $_.PSObject.Properties.Remove($Tag)
                            }
                        }
                        
                        # Evaluate the tags on the policies to be created
                        $TaggedPolicies = Invoke-WTGraphResponseTagging -Tags $Tags -QueryResponse $CreatePolicies

                        # Calculate the display names to be used for the CA groups
                        $CAGroupDisplayNames = foreach ($Policy in $TaggedPolicies) {
                            $DisplayName = $null
                            foreach ($Tag in $Tags) {
                                $DisplayName += $Tag + "-" + $Policy.$Tag + ";"
                            }
                            $DisplayName
                        }

                        # Create include and exclude groups
                        $ConditionalAccessIncludeGroups = New-WTCAGroup @Parameters -DisplayNames $CAGroupDisplayNames -GroupType Include
                        $ConditionalAccessExcludeGroups = New-WTCAGroup @Parameters -DisplayNames $CAGroupDisplayNames -GroupType Exclude
                        
                        # Tag groups
                        $TaggedCAIncludeGroups = Invoke-WTGraphResponseTagging -Tags $Tags -QueryResponse $ConditionalAccessIncludeGroups
                        $TaggedCAExcludeGroups = Invoke-WTGraphResponseTagging -Tags $Tags -QueryResponse $ConditionalAccessExcludeGroups
                        
                        # For each policy, find the matching group
                        $CreatePolicies = foreach ($Policy in $TaggedPolicies) {
                            
                            # Find the matching include group
                            $CAIncludeGroup = $null
                            $CAIncludeGroup = $TaggedCAIncludeGroups | Where-Object {
                                $_.ref -eq $Policy.ref -and $_.env -eq $Policy.env
                            }

                            # Update the property with the group id, which must be in an array, and return the policy
                            $Policy.conditions.users.includeGroups = @($CAIncludeGroup.id)

                            # Find the matching include group
                            $CAExcludeGroup = $null
                            $CAExcludeGroup = $TaggedCAExcludeGroups | Where-Object {
                                $_.ref -eq $Policy.ref -and $_.env -eq $Policy.env
                            }

                            # Update the property with the group id, which must be in an array
                            $Policy.conditions.users.excludeGroups = @($CAExcludeGroup.id)
                            
                            # Return the policy
                            $Policy
                        }

                        # Create policies
                        $ConditionalAccessPolicies = New-WTCAPolicy @Parameters `
                            -ConditionalAccessPolicies $CreatePolicies `
                            -PolicyState $PolicyState
                        
                        # Update configuration files
                        Export-WTCAPolicy -ConditionalAccessPolicies $ConditionalAccessPolicies `
                            -Path $Path `
                            -ExcludeExportCleanup
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
                        Remove-WTCAPolicy @Parameters -RemoveAllExistingPolicies
                    }
                    else {
                        $WarningMessage = "To remove any existing policies use the switch -Force"
                        Write-Warning $WarningMessage
                    }
                }
            }
            else {
                $ErrorMessage = "No access token specified, obtain an access token object from Get-WTGraphAccessToken"
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