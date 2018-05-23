<#
#Script name: Service Plan Licences and Compliance
#Creator: Wesley Trust
#Date: 2018-05-16
#Revision: 4
#References: 

.Synopsis
    Functions to get Azure AD members, check their licence compliance, perform an action as a result, and check licence units/assignments
.Description
    These functions return a member compliance object, a user account action object (based on compliance), as well as an SKU unit amounts/assignments/analysis.
.Example
    
#>
function Get-AzureADMember {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the display name of group to check, multiple groups can be comma separated or in an array",
            ValueFromPipeLineByPropertyName=$true
        )]
        [string[]]
        $GroupDisplayName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to check group membership recursively for nested groups (default: true)"
        )]
        [bool]
        $Recurse = $true,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the display name of user to check, multiple names can be comma separated or in an array",
            ValueFromPipeLineByPropertyName=$true
        )]
        [string[]]
        $UserDisplayName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the UPN of user to check, multiple UPNs can be comma separated or in an array",
            ValueFromPipeLineByPropertyName=$true
        )]
        [string[]]
        $UserPrincipalName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether all users should be included"
        )]
        [switch]
        $AllUsers,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify account status to check"
        )]
        [Nullable[bool]]
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
            # Create array
            $AzureADMemberUsers = @()
            
            # If all users switch is true, get all users, else use property values
            if ($AllUsers) {
                $AzureADMemberUsers = Get-AzureADUser -All $true
            }
            else {
                # Get users to analyse
                if ($GroupDisplayName){
                    
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
                    
                    # Filter on object type
                    $AzureADMemberUsers += $AzureADMembers | Where-Object ObjectType -eq "User"
                    $AzureADMemberGroups = $AzureADMembers | Where-Object ObjectType -eq "Group"

                    # If recurse is true, recall function and iterate until no groups remain, appending
                    if ($Recurse){
                        if ($AzureADMemberGroups){
                            if ($AzureADMemberGroups.DisplayName -contains $AzureADGroups.DisplayName){
                                $ErrorMessage = "Circular reference, child group is a member of the parent group"
                                Write-Error $ErrorMessage
                                throw $ErrorMessage
                            }
                            else {
                                $AzureADMemberUsers += $AzureADMemberGroups | ForEach-Object {
                                    Get-AzureADMember -GroupDisplayName $_.DisplayName -Recurse $Recurse -AccountEnabled $AccountEnabled
                                }
                            }

                        }
                    }
                }
                else {
                    Write-Output "Does not contain group"
                }
            }
            if ($UserDisplayName) {
                # Split and trim input
                $UserDisplayName = $UserDisplayName.Split(",")
                $UserDisplayName = $UserDisplayName.Trim()

                # Get Members of Azure AD Group
                $UserDisplayName | ForEach-Object {
                    $AzureADMemberUsers += Get-AzureADUser -Filter "DisplayName eq '$_'"
                }
            }
            if ($UserPrincipalName){

                # Split and trim input
                $UserUPN = $UserUPN.Split(",")
                $UserUPN = $UserUPN.Trim()

                # Get Members of Azure AD Group
                $UserUPN | ForEach-Object {
                    $AzureADMemberUsers += Get-AzureADUser -Filter "UserPrincipalName eq '$_'"
                }
            }

            # Unique members
            $AzureADMemberUsers = $AzureADMemberUsers | Select-Object -Unique
            
            # Evaluate account enabled property
            if(![string]::IsNullOrEmpty($AccountEnabled)){
                $AzureADMemberUsers = $AzureADMemberUsers | Where-Object AccountEnabled -eq $AccountEnabled
              }

            # Return objects
            return $AzureADMemberUsers
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
function Get-UserServicePlanCompliance {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the Azure AD members to check"
        )]
        [psobject]
        $AzureADMembers,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the licence service plan ID to check"
        )]
        [string]
        $ServicePlanId,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify service plan provisioning status required"
        )]
        [string]
        $ServicePlanProvisioningStatus
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

            # If there are members, check licence compliance for each member
            if ($AzureADMembers){
                $UserComplianceStatus = foreach ($Member in $AzureADMembers){
                    
                    # Assigned Service Plan
                    $MemberAssignedServicePlan = $Member.AssignedPlans | Where-Object ServicePlanId -eq $ServicePlanId
                    
                    # Get user licence details
                    $AzureADUserLicenseDetail = Get-AzureADUserLicenseDetail -ObjectId $Member.ObjectId

                    # Get service plans for user
                    $UserServicePlans = $AzureADUserLicenseDetail | Select-Object -ExpandProperty ServicePlans

                    # Filter to specific service plan
                    $UserSpecificServicePlan = $UserServicePlans `
                        | Where-Object {
                            $_.ServicePlanId -eq $ServicePlanId
                        }
                    
                    # Build object properties
                    $ObjectProperties = @{
                        ObjectID = $Member.ObjectId
                        DisplayName = $Member.DisplayName
                        UserPrincipalName = $Member.UserPrincipalName
                        AccountEnabled = $Member.AccountEnabled
                        AssignedLicenses = $Member.AssignedLicenses
                        AssignedPlans = $MemberAssignedServicePlan
                        ServicePlanId = $ServicePlanId
                    }

                    # Filter to user service plan status
                    $UserStatusServicePlan = $UserSpecificServicePlan `
                        | Where-Object {
                            $_.ProvisioningStatus -eq $ServicePlanProvisioningStatus
                        } `
                        | Select-Object -Unique

                    # If service plan exists, append to object
                    if ($UserStatusServicePlan){
                        $ObjectProperties += @{
                            ServicePlanName = $UserStatusServicePlan.ServicePlanName
                            ComplianceStatus = $true
                        }
                    }
                    # If service plan does not exist, append variable to property
                    else {
                        $ObjectProperties += @{
                            ComplianceStatus = $false
                            ComplianceStatusDetail = $UserSpecificServicePlan
                        }
                    }

                    # Create new object per member with licence status information
                    New-Object psobject -Property $ObjectProperties
                }
                                
                # Return objects
                return $UserComplianceStatus
            }
            else {
                Write-Output "No members specified to check"
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
            HelpMessage="Specify the object id",
            Position=0,
            ValueFromPipeLineByPropertyName=$true
        )]
        [string]
        $ObjectId,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the original account status"
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
            # Invert Parameter
            $AccountEnabled = !$AccountEnabled
            
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
function Get-ServicePlanSku {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the licence service plan ID to check"
        )]
        [string]
        $ServicePlanId
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
                | Select-Object SkuPartNumber,SkuId,ConsumedUnits,CapabilityStatus `
                -ExpandProperty ServicePlans

            # Filter to Service Plan
            $AvailableServicePlan = $AvailableServicePlans `
                | Where-Object ServicePlanId -EQ $ServicePlanId

            # If there are SKUs with the service plan
            if ($AvailableServicePlan){
                $ServicePlanSku = $AvailableServicePlan | ForEach-Object {

                    # Get prepaid units
                    $SubscribedSkuPrepaidUnits = Get-AzureADSubscribedSku `
                        | Where-Object SkuPartNumber -eq $_.SkuPartNumber `
                        | Select-Object -ExpandProperty PrepaidUnits

                    # Calculate available within SKU
                    $AvailableUnits = $SubscribedSkuPrepaidUnits.Enabled - $_.ConsumedUnits
                    
                    # Build object
                    [PSCustomObject]@{
                        SkuPartNumber = $_.SkuPartNumber
                        SkuId = $_.SkuId
                        ConsumedUnits = $_.ConsumedUnits
                        CapabilityStatus = $_.CapabilityStatus
                        AppliesTo = $_.AppliesTo
                        ProvisioningStatus = $_.ProvisioningStatus
                        ServicePlanId = $_.ServicePlanId
                        ServicePlanName = $_.ServicePlanName
                        Enabled = $SubscribedSkuPrepaidUnits.Enabled
                        Suspended = $SubscribedSkuPrepaidUnits.Suspended
                        Warning = $SubscribedSkuPrepaidUnits.Warning
                        Available = $AvailableUnits
                    }
                }
            }
            # Return object
            return $ServicePlanSku
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
function Get-SkuConsumptionSummary {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the service plan sku object",
            Position=0,
            ValueFromPipeLine=$true
        )]
        [psobject]
        $InputObject
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
            # Get Summary
            $SkuConsumptionSummary = $InputObject | ForEach-Object {
                $ObjectProperties = @{
                    SkuPartNumber = $_.SkuPartNumber
                    SkuId = $_.SkuId
                    EnabledUnits = $_.Enabled
                    ConsumedUnits = $_.ConsumedUnits
                    AvailableUnits = $_.Available
                }
                if ($_.Available -eq "0"){
                    $ObjectProperties += @{
                        Status = "Caution"
                        StatusDetail = "No available units, consider capacity/demand management"
                    }
                }
                elseif ($_.Available -lt "0"){
                    $ObjectProperties += @{
                        Status = "Warning"
                        StatusDetail = "Available units in deficit, licences will expire soon"
                    }
                }
                elseif ($_.Available -gt "0"){
                    $ObjectProperties += @{
                        Status = "Informational"
                        StatusDetail = "Consider reducing licence count"
                    }
                }
                New-Object -TypeName psobject -Property $ObjectProperties
            }
            # Return object
            return $SkuConsumptionSummary
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
function Get-UserSkuConsumptionSummary {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the user input object",
            Position=0,
            ValueFromPipeLine=$true
        )]
        [psobject]
        $InputObject,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the object id"
        )]
        [psobject]
        $SkuConsumption
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

            # Get Sku consumption
            $UserConsumptionSummary = $InputObject | ForEach-Object {
                $ObjectProperties = @{
                    ObjectId = $_.ObjectId
                    DisplayName = $_.DisplayName
                    UserPrincipalName = $_.UserPrincipalName
                    AccountEnabled = $_.AccountEnabled
                    SkuPartNumber = $SkuConsumption.SkuPartNumber
                    SkuId = $SkuConsumption.SkuId
                }
                if ($_.AssignedLicenses.skuid -contains $SkuConsumption.SkuId){
                    $ObjectProperties += @{
                        SkuAssigned = $true
                    }
                }
                else {
                    $ObjectProperties += @{
                        SkuAssigned = $false
                    }
                }
                New-Object -TypeName psobject -Property $ObjectProperties
            }
            # Return object
            return $UserConsumptionSummary
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}
function Get-SkuServicePlanUnitSummary {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the service plan sku object",
            Position=0,
            ValueFromPipeLine=$true
        )]
        [psobject]
        $InputObject
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
            # Calculate total licences
            $InputObject | ForEach-Object {
                $TotalEnabled += $_.Enabled
                $TotalConsumed +=  $_.ConsumedUnits
                $TotalSuspended += $_.Suspended
                $TotalWarning += $_.Warning
                $TotalAvailable += $_.Available
            }
            # Unique variables
            $ServicePlanId = $InputObject.ServicePlanId | Select-Object -Unique
            $ServicePlanName = $InputObject.ServicePlanName | Select-Object -Unique

            # Build Totals Object
            $ServicePlanUnitSummary =[PSCustomObject]@{
                ServicePlanName = $ServicePlanName
                ServicePlanId = $ServicePlanId
                TotalEnabledUnits = $TotalEnabled
                TotalConsumedUnits = $TotalConsumed
                TotalAvailableUnits = $TotalAvailable
                TotalWarningUnits = $TotalWarning
                TotalSuspendedUnits = $TotalSuspended
            }
            # Return object
            return $ServicePlanUnitSummary
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}