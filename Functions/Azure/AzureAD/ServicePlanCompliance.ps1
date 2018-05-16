<#
#Script name: Service Plan Licences and Compliance
#Creator: Wesley Trust
#Date: 2018-05-16
#Revision: 1
#References: 

.Synopsis
    Functions to get members of a group and check their licence compliance, perform an action as a result, and check licence units
.Description
    These functions return a compliance object of group members, a user account status object, based on compliance, as well as an object of licence units.
.Example
    Get-GroupMemberServicePlanCompliance -GroupDisplayName $GroupDisplayName -ServicePlanId $ServicePlanId -LicenceStatus $LicenceStatus -AccountEnabled $AccountEnabled

    Set-UserAccountEnabledOnComplianceStatus -ObjectId $ObjectId -AccountEnabled $AccountEnabled -ComplianceStatus $ComplianceStatus
    
    Get-TotalServicePlanUnits -LicenceStatus $LicenceStatus
.Example
    
#>

function Get-GroupMemberServicePlanCompliance {
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
            HelpMessage="Specify desired account enabled status if non-compliant"
        )]
        [bool]
        $AccountEnabled
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
            $FilteredGroupMembers = $AzureADGroupMembers | Where-Object $_.AccountEnabled -ne $AccountEnabled
            
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
                    
                    # Filter to specific unique service plan with licence status
                    $UserServicePlan = $UserServicePlans `
                        | Where-Object {ServicePlanId -eq $ServicePlanId -and ProvisioningStatus -eq $LicenceStatus} `
                        | Select-Object -Unique
                    
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
                
                $ComplianceStatus = $UserLicenceCheck | ForEach-Object {
                    # Build object
                    $ObjectProperties = @{
                        ObjectID = $_.ObjectId
                        DisplayName = $_.DisplayName
                        UserPrincipalName = $_.UserPrincipalName
                        ServicePlanId = $_.ServicePlanId
                        Licence = $_.Licence
                        Status = $_.Status
                        AccountEnabled = $AzureADUser.AccountEnabled
                    }
                    # Include action status
                    if ($_.status -ne $AccountEnabled){
                        $ObjectProperties += @{
                            ComplianceStatus = $false
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            ComplianceStatus = $true
                        }
                    }
                    # Create object
                    New-Object psobject -Property $ObjectProperties
                }
                
                # Return objects
                return $ComplianceStatus
            }
            else {
                Write-Output "No members with account enabled status of $AccountEnabled for group $GroupDisplayName"
            }
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
function Set-UserAccountEnabledOnComplianceStatus {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the object id"
        )]
        [string]
        $ObjectId,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the intended account status if compliance status is false"
        )]
        [bool]
        $AccountEnabled,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the compliance status"
        )]
        [bool]
        $ComplianceStatus
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
            # If compliance status is false
            if (!$ComplianceStatus){
                Set-AzureADUser -ObjectID $ObjectId -AccountEnabled $AccountEnabled

                    # Check this has applied
                    $AzureADUser = Get-AzureADUser -ObjectId $ObjectId
                    
                    # Build object
                    $ObjectProperties = @{
                        ObjectID = $AzureADUser.ObjectId
                        DisplayName = $AzureADUser.DisplayName
                        UserPrincipalName = $AzureADUser.UserPrincipalName
                        AccountEnabled = $AzureADUser.AccountEnabled
                    }
                    # Include action status
                    if ($AzureADUser.AccountEnabled -eq $AccountEnabled){
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
                    $ComplianceActionStatus = New-Object psobject -Property $ObjectProperties
            }
            # Return Compliance Action Status
            return $ComplianceActionStatus
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
function Get-TotalServicePlanUnits {
    Param(
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
        $LicenceStatus
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
            # Return object
            return $TotalServicePlanUnits
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}