<#
#Script name: Set user account enabled parameter based on licence status and group membership
#Creator: Wesley Trust
#Date: 2018-05-14
#Revision: 2
#References: 

.Synopsis
    Gets members of a group, checks whether they have a specific service plan and changes Account Enabled status.
.Description
    This function returns a compliance object of whether the users in a group, are compliant with the criteria.
    Implementing the account enabled action as appropriate, checking whether this is successful, and returning all user compliance results.
.Example
    Set-AccountStatusOnLicenceInGroup -GroupDisplayName $Name -ServicePlanId $ServicePlan -$LicenceStatus "Success" -$AccountStatus $false
.Example
    
#>

# Exisiting function
function Set-AccountStatusOnLicenceInGroup {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the display name of group to check"
        )]
        [string]
        $GroupDisplayName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the licence service plan ID to check"
        )]
        [string]
        $ServicePlanId,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify licence status required"
        )]
        [string]
        $LicenceStatus,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify account action if required licence status is not found"
        )]
        [bool]
        $AccountStatus
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
            # Variables
            $NoLicence = "No licence found"
            $NoLicenceStatus = "Error"

            # Get Azure AD Group
            $AzureADGroup = Get-AzureADGroup -Filter "DisplayName eq '$GroupDisplayName'"

            # Get Members of Azure AD Group
            $AzureADGroupMembers = Get-AzureADGroupMember -ObjectId $AzureADGroup.ObjectId

            # Filter members
            $FilteredGroupMembers = $AzureADGroupMembers | Where-Object $_.AccountEnabled -ne $AccountStatus
            
            # If there are members, check licence for each member
            if ($FilteredGroupMembers){
                $UserLicenceCheck = foreach ($Member in $FilteredGroupMembers){
                    # Build object properties
                    $ObjectProperties = @{
                        ObjectID = $Member.ObjectId
                        DisplayName = $Member.DisplayName
                        UserPrincipalName = $Member.UserPrincipalName
                        ServicePlanId = $ServicePlanId
                    }
                    # Get service plans for user
                    $UserServicePlans = Get-AzureADUserLicenseDetail -ObjectId $Member.ObjectId `
                        | Select-Object -ExpandProperty ServicePlans
                    
                    # Filter to specific service plan
                    $UserServicePlan = $UserServicePlans | Where-Object ServicePlanId -eq $ServicePlanId
                    
                    # If service plan exists, append to object
                    if ($UserServicePlan){
                        $ObjectProperties += @{
                            Licence = $UserServicePlan.ServicePlanName
                            Status = $UserServicePlan.ProvisioningStatus
                        }
                    }
                    # If service plan does not exist, append variable to property
                    else {
                        $ObjectProperties += @{
                            Licence = $NoLicence
                            Status = $NoLicenceStatus
                        }
                    }
                    # Create new object per member with licence status information
                    New-Object psobject -Property $ObjectProperties
                }
                
                # For any user without the specified licence status, set the account enabled attribute
                $NonCompliantUsers = $UserLicenceCheck | Where-Object Status -ne $LicenceStatus

                # Get Service Plans
                $AvailableServicePlans = Get-AzureADSubscribedSku `
                    | Select-Object SkuPartNumber,ConsumedUnits,CapabilityStatus `
                    -ExpandProperty ServicePlans

                # Filter to Service Plan
                $AvailableServicePlan = $AvailableServicePlans `
                    | Where-Object ServicePlanId -EQ $ServicePlanId

                # If there are SKUs with the service plan
                if ($AvailableServicePlan){
                    $ServicePlanPrepaidUnits = $AvailableServicePlan | ForEach-Object {

                        # Get prepaid units
                        $AvailableSubscribedSkuPrepaidUnits = Get-AzureADSubscribedSku `
                            | Where-Object SkuPartNumber -eq $_.SkuPartNumber `
                            | Select-Object -ExpandProperty PrepaidUnits

                        # Build object
                        [PSCustomObject]@{
                            SkuPartNumber = $_.SkuPartNumber
                            ConsumedUnits = $_.ConsumedUnits
                            CapabilityStatus = $_.CapabilityStatus
                            AppliesTo = $_.AppliesTo
                            ProvisioningStatus = $_.ProvisioningStatus
                            ServicePlanId = $_.ServicePlanId
                            ServicePlanName = $_.ServicePlanName
                            Enabled = $AvailableSubscribedSkuPrepaidUnits.Enabled
                            Suspended  = $AvailableSubscribedSkuPrepaidUnits.Suspended
                            Warning  = $AvailableSubscribedSkuPrepaidUnits.Warning
                        }
                    }
                    
                    # Calculate total licences
                    $ServicePlanPrepaidUnits | ForEach-Object {
                        $TotalEnabled += $_.Enabled
                        $TotalConsumed +=  $_.ConsumedUnits
                    }
                
                    # Calculate available units
                    $AvailableUnits = $TotalEnabled - $TotalConsumed
                    
                    # Unique variables
                    $ServicePlanId = $ServicePlanPrepaidUnits.ServicePlanId | Select-Object -Unique
                    $ServicePlanName = $ServicePlanPrepaidUnits.ServicePlanName | Select-Object -Unique

                    # Build Totals Object
                    $TotalServicePlanUnits =[PSCustomObject]@{
                        TotalEnabledUnits = $TotalEnabled
                        TotalConsumedUnits = $TotalConsumed
                        TotalAvailableUnits = $AvailableUnits
                        ServicePlanId = $ServicePlanId
                        ServicePlanName = $ServicePlanName
                    }
                }
                else {
                    Write-Output "No available SKUs with the Service Plan, an appropriate subscription should be purchased"
                }

                if ($NonCompliantUsers){
                    $NonCompliantUserStatus = $NonCompliantUsers | ForEach-Object {
                        Set-AzureADUser -ObjectID $_.ObjectId -AccountEnabled $AccountStatus
                        # Check this has applied
                        $AzureADUser = Get-AzureADUser -ObjectId $_.ObjectId
                        # Build object
                        $ObjectProperties = @{
                            ObjectID = $_.ObjectId
                            DisplayName = $_.DisplayName
                            UserPrincipalName = $_.UserPrincipalName
                            ServicePlanId = $_.ServicePlanId
                            Licence = $_.Licence
                            Status = $_.Status
                            AccountEnabled = $AzureADUser.AccountEnabled
                            ComplianceStatus = "Non-compliant"
                        }
                        # Include action status
                        if ($AzureADUser.AccountEnabled -eq $AccountStatus){
                            $ObjectProperties += @{
                                ActionStatus = "Successfully changed account enabled property"
                            }
                        }
                        else {
                            $ObjectProperties += @{
                                ActionStatus = "Failed to change account enabled property"
                            }
                        }
                        # Create object
                        New-Object psobject -Property $ObjectProperties
                    }
                }
                # For users with correct licence status
                $CompliantUsers = $UserLicenceCheck | Where-Object Status -eq $LicenceStatus
                if ($CompliantUsers){
                    $CompliantUserStatus = $CompliantUsers | ForEach-Object {
                        # Build object
                        $ObjectProperties = @{
                            ObjectID = $_.ObjectId
                            DisplayName = $_.DisplayName
                            UserPrincipalName = $_.UserPrincipalName
                            ServicePlanId = $_.ServicePlanId
                            Licence = $_.Licence
                            Status = $_.Status
                            AccountEnabled = $AzureADUser.AccountEnabled
                            ComplianceStatus = "Compliant"
                        }
                        # Create object
                        New-Object psobject -Property $ObjectProperties
                    }
                }
                
                # Return objects
                return $NonCompliantUserStatus
                return $CompliantUserStatus
                return $TotalServicePlanUnits
            }
            else {
                Write-Output "No members with account enabled status of $AccountStatus for group $GroupDisplayName"
            }
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
