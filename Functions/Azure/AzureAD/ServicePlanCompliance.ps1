<#
#Script name: Service Plan Licences and Compliance
#Creator: Wesley Trust
#Date: 2018-05-16
#Revision: 7
#References: 

.Synopsis
    Functions to check Azure AD user licence compliance, perform an action as a result, and check SKU Service Plan unit consumption, and user consumption.
.Description
    These functions return a member compliance object, a user account action object (based on compliance), as well as SKU unit amounts/assignment/summary objects.
.Example
    
#>
function Get-UserServicePlanCompliance {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the Azure AD members to check"
        )]
        [psobject]
        $AzureADMembers,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the licence service plan ID to check"
        )]
        [string]
        $ServicePlanId,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify service plan provisioning status required"
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

            # If there are members, unique input and check licence compliance for each member
            if ($AzureADMembers) {
                
                # $AzureADMembers = $AzureADMembers | Sort-Object ObjectId -Unique
                $UserComplianceStatus = foreach ($Member in $AzureADMembers) {
                    
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
                        ObjectID          = $Member.ObjectId
                        DisplayName       = $Member.DisplayName
                        UserPrincipalName = $Member.UserPrincipalName
                        AccountEnabled    = $Member.AccountEnabled
                        AssignedLicenses  = $Member.AssignedLicenses
                        AssignedPlans     = $MemberAssignedServicePlan
                        ServicePlanId     = $ServicePlanId
                    }

                    # Filter to user service plan status
                    $UserStatusServicePlan = $UserSpecificServicePlan `
                        | Where-Object {
                        $_.ProvisioningStatus -eq $ServicePlanProvisioningStatus
                    } `
                        | Sort-Object -Unique

                    # If service plan exists, append to object
                    if ($UserStatusServicePlan) {
                        $ObjectProperties += @{
                            ServicePlanName  = $UserStatusServicePlan.ServicePlanName
                            ComplianceStatus = $true
                        }
                    }
                    
                    # If service plan does not exist, append variable to property
                    else {
                        $ObjectProperties += @{
                            ComplianceStatus       = $false
                            ComplianceStatusDetail = $UserSpecificServicePlan
                        }
                    }

                    # Create new object per member with licence status information
                    New-Object psobject -Property $ObjectProperties
                }

                # Sort object
                $UserComplianceStatus = $UserComplianceStatus | Sort-Object ComplianceStatus
                                
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
        try {

        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
}
function Set-UserAccountEnabledOnComplianceStatus {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the object id",
            Position = 0,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string]
        $ObjectId,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the original account status"
        )]
        [bool]
        $AccountEnabled,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the compliance status"
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
            if (!$ComplianceStatus) {
                Set-AzureADUser -ObjectID $ObjectId -AccountEnabled $AccountEnabled

                # Check this has applied
                $AzureADUser = Get-AzureADUser -ObjectId $ObjectId
                    
                # Build object
                $ObjectProperties = @{
                    ObjectID          = $AzureADUser.ObjectId
                    DisplayName       = $AzureADUser.DisplayName
                    UserPrincipalName = $AzureADUser.UserPrincipalName
                    AccountEnabled    = $AzureADUser.AccountEnabled
                }
                
                # Include action status
                if ($AzureADUser.AccountEnabled -eq $AccountEnabled) {
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
                
                return $ComplianceActionStatus
            }
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {
        try {

        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
}
function Get-ServicePlanSku {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the licence service plan ID to check"
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
                | Select-Object SkuPartNumber, SkuId, ConsumedUnits, CapabilityStatus `
                -ExpandProperty ServicePlans

            # Filter to Service Plan
            $AvailableServicePlan = $AvailableServicePlans `
                | Where-Object ServicePlanId -EQ $ServicePlanId

            # If there are SKUs with the service plan
            if ($AvailableServicePlan) {
                $ServicePlanSku = foreach ($ServicePlan in $AvailableServicePlan) {

                    # Get prepaid units
                    $SubscribedSkuPrepaidUnits = Get-AzureADSubscribedSku `
                        | Where-Object SkuPartNumber -eq $ServicePlan.SkuPartNumber `
                        | Select-Object -ExpandProperty PrepaidUnits

                    # Calculate available within SKU
                    $AvailableUnits = $SubscribedSkuPrepaidUnits.Enabled - $ServicePlan.ConsumedUnits
                    
                    # Build object
                    [PSCustomObject]@{
                        SkuPartNumber      = $ServicePlan.SkuPartNumber
                        SkuId              = $ServicePlan.SkuId
                        ConsumedUnits      = $ServicePlan.ConsumedUnits
                        CapabilityStatus   = $ServicePlan.CapabilityStatus
                        AppliesTo          = $ServicePlan.AppliesTo
                        ProvisioningStatus = $ServicePlan_.ProvisioningStatus
                        ServicePlanId      = $ServicePlan.ServicePlanId
                        ServicePlanName    = $ServicePlan.ServicePlanName
                        Enabled            = $SubscribedSkuPrepaidUnits.Enabled
                        Suspended          = $SubscribedSkuPrepaidUnits.Suspended
                        Warning            = $SubscribedSkuPrepaidUnits.Warning
                        Available          = $AvailableUnits
                    }
                }
            }

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
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the service plan sku object",
            Position = 0,
            ValueFromPipeLine = $true
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
            $SkuConsumptionSummary = foreach ($Object in $InputObject) {
                $ObjectProperties = @{
                    SkuPartNumber  = $Object.SkuPartNumber
                    SkuId          = $Object.SkuId
                    EnabledUnits   = $Object.Enabled
                    ConsumedUnits  = $Object.ConsumedUnits
                    AvailableUnits = $Object.Available
                }
                if ($Object.Available -eq "0") {
                    $ObjectProperties += @{
                        Status       = "Caution"
                        StatusDetail = "No available units, consider capacity/demand management"
                    }
                }
                elseif ($Object.Available -lt "0") {
                    $ObjectProperties += @{
                        Status       = "Warning"
                        StatusDetail = "Available units in deficit, licences will expire soon"
                    }
                }
                elseif ($Object.Available -gt "0") {
                    $ObjectProperties += @{
                        Status       = "Informational"
                        StatusDetail = "Consider reducing licence count"
                    }
                }
                New-Object -TypeName psobject -Property $ObjectProperties
            }

            return $SkuConsumptionSummary
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {
        try {

        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
}
function Get-UserSkuConsumptionSummary {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the user input object",
            Position = 0,
            ValueFromPipeLine = $true
        )]
        [psobject]
        $InputObject,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the object id"
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
            $UserConsumptionSummary = foreach ($Object in $InputObject) {
                $ObjectProperties = @{
                    ObjectId          = $Object.ObjectId
                    DisplayName       = $Object.DisplayName
                    UserPrincipalName = $Object.UserPrincipalName
                    AccountEnabled    = $Object.AccountEnabled
                    SkuPartNumber     = $SkuConsumption.SkuPartNumber
                    SkuId             = $SkuConsumption.SkuId
                }
                if ($Object.AssignedLicenses.skuid -contains $SkuConsumption.SkuId) {
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
            return $UserConsumptionSummary
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {
        try {

        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
}
function Get-SkuServicePlanUnitSummary {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the service plan sku object",
            Position = 0,
            ValueFromPipeLine = $true
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
            foreach ($Object in $InputObject) {
                $TotalEnabled += $Object.Enabled
                $TotalConsumed += $Object.ConsumedUnits
                $TotalSuspended += $Object.Suspended
                $TotalWarning += $Object.Warning
                $TotalAvailable += $Object.Available
            }
            
            # Unique variables
            $ServicePlanId = $InputObject.ServicePlanId | Sort-Object -Unique
            $ServicePlanName = $InputObject.ServicePlanName | Sort-Object -Unique
            
            # Build Totals Object
            $ServicePlanUnitSummary = [PSCustomObject]@{
                ServicePlanName     = $ServicePlanName
                ServicePlanId       = $ServicePlanId
                TotalEnabledUnits   = $TotalEnabled
                TotalConsumedUnits  = $TotalConsumed
                TotalAvailableUnits = $TotalAvailable
                TotalWarningUnits   = $TotalWarning
                TotalSuspendedUnits = $TotalSuspended
            }
            return $ServicePlanUnitSummary
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {
        try {

        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
}