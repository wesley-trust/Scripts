<#
#Script name: Get Azure AD Member
#Creator: Wesley Trust
#Date: 2018-05-16
#Revision: 8
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
    [CmdletBinding()]
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
        $Recursive = $true,
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

                    # Split, trim & unique input
                    $UserDisplayName = $UserDisplayName.Split(",")
                    $UserDisplayName = $UserDisplayName.Trim()
                    $UserDisplayName = $UserDisplayName | Sort-Object -Unique
    
                    # Get Members of Azure AD Group
                    $AzureADMemberUsers = foreach ($DisplayName in $UserDisplayName) {
                        Get-AzureADUser -Filter "DisplayName eq '$DisplayName'"
                    }
                    
                    # Add user objects
                    foreach ($MemberUser in $AzureADMemberUsers) {
                        $script:AzureADMemberUsersTotal.add($MemberUser) 
                    }
                }
                if ($UserPrincipalName) {
    
                    # Split, trim & unique input
                    $UserUPN = $UserUPN.Split(",")
                    $UserUPN = $UserUPN.Trim()
                    $UserUPN = $UserUPN | Sort-Object -Unique
                    
                    # Get Members of Azure AD Group
                    $AzureADMemberUsers = foreach ($UPN in $UserUPN) {
                        Get-AzureADUser -Filter "UserPrincipalName eq '$UPN'"
                    }
                    
                    # Add user objects
                    foreach ($MemberUser in $AzureADMemberUsers) {
                        $script:AzureADMemberUsersTotal.add($MemberUser) 
                    }
                }
                if ($GroupDisplayName) {
                    
                    # Split, trim & unique input
                    $GroupDisplayName = $GroupDisplayName.Split(",")
                    $GroupDisplayName = $GroupDisplayName.Trim()
                    $GroupDisplayName = $GroupDisplayName | Sort-Object -Unique
                    
                    # Get Azure AD Group
                    $AzureADGroups = foreach ($DisplayName in $GroupDisplayName) {
                        Get-AzureADGroup -Filter "DisplayName eq '$DisplayName'"
                    }

                    # Get Members of Azure AD Group
                    $AzureADMembers = foreach ($GroupMember in $AzureADGroups) {
                        Get-AzureADGroupMember -ObjectId $GroupMember.ObjectId -All $true
                    }
                    
                    # Filter on user object type
                    $AzureADMemberUsers = $AzureADMembers | Where-Object ObjectType -eq "User"

                    # Add user objects
                    foreach ($MemberUser in $AzureADMemberUsers) {
                        $script:AzureADMemberUsersTotal.add($MemberUser) 
                    }

                    # If Recursive is true, filter to member groups
                    if ($Recursive) {

                        # Filter on group object type
                        $AzureADMemberGroups = $AzureADMembers | Where-Object ObjectType -eq "Group"
                        
                        # If there are member groups
                        if ($AzureADMemberGroups) {

                            # Create group collection object
                            if (!$Script:AzureADGroupsTotal) {
                                $Script:AzureADGroupsTotal = New-Object System.Collections.Generic.List[System.Object]
                            }

                            # Add group objects to object list
                            foreach ($ADGroup in $AzureADGroups) {
                                $Script:AzureADGroupsTotal.add($ADGroup)
                            }

                            # Create member group collection object
                            if (!$Script:AzureADMemberGroups) {
                                $Script:AzureADMemberGroups = New-Object System.Collections.Generic.List[System.Object]
                            }

                            # Infinite loop protection
                            foreach ($ADMemberGroup in $AzureADMemberGroups) {
                                if ($ADMemberGroup -in $script:AzureADGroupsTotal) {
                                    
                                    # Set flag and display error
                                    $Script:CircularReference = $true
                                    $ErrorMessage = "Circular reference, '$($ADMemberGroup.DisplayName)' is a member of parent group '$GroupDisplayName'"
                                    Write-Error $ErrorMessage
                                }
                                else {
                                    # Add member group objects to object list
                                    $Script:AzureADMemberGroups.add($ADMemberGroup)
                                    
                                    # Iterate through child group
                                    Get-AzureADMember -GroupDisplayName $ADMemberGroup.DisplayName -Recursive $Recursive -AccountEnabled $AccountEnabled -UserType $UserType
                                    
                                    # Remove member group objects from object list
                                    [void]$Script:AzureADMemberGroups.Remove($ADMemberGroup)
                                }
                            }
                        }
                    }
                }
            }

            # If there are no nested groups remaining to iterate
            if (!$Script:AzureADMemberGroups) {

                if ($GroupDisplayName) {
                    $VerboseMessage = "Final iteration of group $GroupDisplayName, that contained $($Script:AzureADGroupsTotal.count) nested group(s) and $($AzureADMemberUsers.count) user(s)"
                    Write-Verbose $VerboseMessage
                }

                if (!$AzureADMemberUsersTotal) {
                    # If no circular reference, move scope for output
                    if (!$Script:CircularReference) {
                        # Move to local scope
                        $AzureADMemberUsersTotal = $Script:AzureADMemberUsersTotal
                    }
                    # Move scope to clear variable
                    else {
                        $CircularReference = $Script:CircularReference
                        $Script:CircularReference = $null
                    }
                }
                
                # Clean up script scope variables
                $Script:AzureADGroupsTotal = $null
                $Script:AzureADMemberUsersTotal = $null
                $Script:AzureADMemberGroups = $null

                # If there is a circular reference, throw error after variables have been cleared
                if ($CircularReference) {
                    $ErrorMessage = "Halting execution after clearing scope variables"
                    throw $ErrorMessage
                }

                $VerboseMessage = "Total unfiltered users across all parameters: $($AzureADMemberUsersTotal.count)"
                Write-Verbose $VerboseMessage

                # Evaluate account enabled property
                if (![string]::IsNullOrEmpty($AccountEnabled)) {
                    $AzureADMemberUsersTotal = $AzureADMemberUsersTotal | Where-Object AccountEnabled -eq $AccountEnabled

                    $VerboseMessage = "Total users after filtering on account enabled '$AccountEnabled': $($AzureADMemberUsersTotal.count)"
                    Write-Verbose $VerboseMessage
                }

                # Evaluate user type
                if ($UserType) {
                    $AzureADMemberUsersTotal = $AzureADMemberUsersTotal | Where-Object UserType -eq $UserType

                    $VerboseMessage = "Total users after filtering on user type '$UserType': $($AzureADMemberUsersTotal.count)"
                    Write-Verbose $VerboseMessage
                }

                # Sort and unique
                $AzureADMemberUsersTotal = $AzureADMemberUsersTotal | Sort-Object DisplayName -Unique

                $VerboseMessage = "Final user total after sorting unique: $($AzureADMemberUsersTotal.count) "
                Write-Verbose $VerboseMessage
                    
                # Return output
                return $AzureADMemberUsersTotal
            }
            else {
                $VerboseMessage = "Iterating group $GroupDisplayName that contains $($AzureADMemberGroups.count) nested group(s) and $($AzureADMemberUsers.count) user(s)"
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