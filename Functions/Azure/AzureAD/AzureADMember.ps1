<#
#Script name: Get Azure AD Member
#Creator: Wesley Trust
#Date: 2018-05-16
#Revision: 6
#References: 

.Synopsis
    Function to get Azure AD members, using a group display name, user display name or user principal name with filtering available.
.Description
    Certain parameter values can be in an array, or comma separated, input is trimmed.
    Group recursion is on by default but can be turned off. Circular recursion protection to prevent infinite  loops is present.
    All users can also be included for filtering.
    Account enabled and user type parameters can filter users further (null is allowed for these parameters).
    Results are sorted by display name and only unique values are returned.
.Example
    Get-AzureADMember -GroupDisplayName $GroupDisplayName -AccountEnabled $true -UserType "Member"
#>
function Get-AzureADMember {
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the display name of group to check, multiple groups can be comma separated or in an array",
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $GroupDisplayName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to check group membership recursively for nested groups (default: true)"
        )]
        [bool]
        $Recurse = $true,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the display name of user to check, multiple names can be comma separated or in an array",
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $UserDisplayName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the UPN of user to check, multiple UPNs can be comma separated or in an array",
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $UserPrincipalName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether all users should be included"
        )]
        [switch]
        $AllUsers,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify account status to check"
        )]
        [Nullable[bool]]
        $AccountEnabled,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify user type to check"
        )]
        [ValidateSet("Guest", "Member", "")]
        [AllowNull()]
        [String]
        $UserType
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
            # If all users switch is true, get all users, else use property values
            if ($AllUsers) {
                $AzureADMemberUsersTotal = Get-AzureADUser -All $true
            }
            else {
                # Create user collection object
                if (!$Script:AzureADMemberUsersTotal) {
                    $Script:AzureADMemberUsersTotal = New-Object System.Collections.Generic.List[System.Object]
                }
                if ($UserDisplayName) {

                    # Split and trim input
                    $UserDisplayName = $UserDisplayName.Split(",")
                    $UserDisplayName = $UserDisplayName.Trim()
    
                    # Get Members of Azure AD Group
                    $AzureADMemberUsers = $UserDisplayName | ForEach-Object {
                        Get-AzureADUser -Filter "DisplayName eq '$_'"
                    }
                    
                    # Add user objects
                    $AzureADMemberUsers | Foreach-Object {
                        $script:AzureADMemberUsersTotal.add($_)
                    }
                }
                if ($UserPrincipalName) {
    
                    # Split and trim input
                    $UserUPN = $UserUPN.Split(",")
                    $UserUPN = $UserUPN.Trim()
    
                    # Get Members of Azure AD Group
                    $AzureADMemberUsers = $UserUPN | ForEach-Object {
                        Get-AzureADUser -Filter "UserPrincipalName eq '$_'"
                    }
                    
                    # Add user objects
                    $AzureADMemberUsers | Foreach-Object {
                        $script:AzureADMemberUsersTotal.add($_)
                    }
                }
                if ($GroupDisplayName) {
                    
                    # Split and trim input
                    $GroupDisplayName = $GroupDisplayName.Split(",")
                    $GroupDisplayName = $GroupDisplayName.Trim()
                    
                    # Get Azure AD Group
                    $AzureADGroups = $GroupDisplayName | Foreach-Object {
                        Get-AzureADGroup -Filter "DisplayName eq '$_'"
                    }

                    # Get Members of Azure AD Group
                    $AzureADMembers = $AzureADGroups | ForEach-Object {
                        Get-AzureADGroupMember -ObjectId $_.ObjectId -All $true
                    }
                    
                    # Filter on user object type
                    $AzureADMemberUsers = $AzureADMembers | Where-Object ObjectType -eq "User"

                    # Add user objects
                    $AzureADMemberUsers | Foreach-Object {
                        $script:AzureADMemberUsersTotal.add($_)
                    }
                    
                    # If recurse is true, filter to member groups
                    if ($Recurse) {

                        # Filter on group object type
                        $AzureADMemberGroups = $AzureADMembers | Where-Object ObjectType -eq "Group"

                        if ($AzureADMemberGroups) {

                            # Create group collection object
                            if (!$Script:AzureADGroupsTotal) {
                                $Script:AzureADGroupsTotal = New-Object System.Collections.Generic.List[System.Object]
                            }

                            # Add group objects to object list
                            $AzureADGroups | Foreach-Object {
                                $Script:AzureADGroupsTotal.add($_)
                            }

                            # Create member group collection object
                            if (!$Script:AzureADMemberGroups) {
                                $Script:AzureADMemberGroups = New-Object System.Collections.Generic.List[System.Object]
                            }

                            # Infinite loop protection
                            $AzureADMemberGroups | ForEach-Object {
                                if ($_ -in $script:AzureADGroupsTotal) {
                                    # Set flag and display error
                                    $Script:CircularReference = $true
                                    $ErrorMessage = "Circular reference, '$($_.DisplayName)' is a member of parent group '$GroupDisplayName'"
                                    Write-Error $ErrorMessage
                                }
                                elseif (!$Script:CircularReference) {
                                    # Add member group objects to object list
                                    $Script:AzureADMemberGroups.add($_)
                                    
                                    # Iterate through child group
                                    Get-AzureADMember -GroupDisplayName $_.DisplayName -Recurse $Recurse -AccountEnabled $AccountEnabled -UserType $UserType
                                    
                                    # Remove member group objects from object list
                                    [void]$Script:AzureADMemberGroups.Remove($_)
                                }
                            }
                        }
                    }
                }
            }
            
            # If there are no nested groups remaining to iterate
            if (!$Script:AzureADMemberGroups) {

                if ($GroupDisplayName) {
                    $VerboseMessage = "Final iteration of group $GroupDisplayName"
                    Write-Verbose $VerboseMessage
                }
                if (!$Script:CircularReference){
                    # Move to local scope
                    $AzureADMemberUsersTotal = $Script:AzureADMemberUsersTotal
                }
                else {
                    # Move scope and clean-up
                    $CircularReference = $Script:CircularReference
                    $Script:CircularReference = $null
                }
                
                # Clean up script scope variables
                $Script:AzureADGroupsTotal = $null
                $Script:AzureADMemberUsersTotal = $null
                $Script:AzureADMemberGroups = $null

                # If there is a circular reference, throw error after variables have been cleared
                if ($CircularReference){
                    $ErrorMessage = "Halting script execution due to Circular Reference, script scope variables have been cleared"
                    throw $ErrorMessage
                }

                # Evaluate account enabled property
                if (![string]::IsNullOrEmpty($AccountEnabled)) {
                    $AzureADMemberUsersTotal = $AzureADMemberUsersTotal | Where-Object AccountEnabled -eq $AccountEnabled
                }

                # Evaluate user type
                if ($UserType) {
                    $AzureADMemberUsersTotal = $AzureADMemberUsersTotal | Where-Object UserType -eq $UserType
                }

                # Sort and unique
                $AzureADMemberUsersTotal = $AzureADMemberUsersTotal | Sort-Object DisplayName -Unique
                    
                # Return output
                return $AzureADMemberUsersTotal
            }
            else {
                $VerboseMessage = "Iterating through group $GroupDisplayName that contains $($AzureADMemberGroups.count) nested group(s)"
                Write-Verbose $VerboseMessage
            }
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}