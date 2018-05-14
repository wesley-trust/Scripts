<#
#Script name: Set user account enabled parameter based on licence status and group membership
#Creator: Wesley Trust
#Date: 2018-05-14
#Revision: 1
#References: 

.Synopsis
    Gets members of a group, checks whether they have a specific service plan and changes Account Enabled status.
.Description

.Example
    Set-AccountEnabledOnLicenceStatusInGroup -GroupDisplayName $Name -ServicePlanId $ServicePlan -$LicenceStatus "Success" -AccountEnabled $true
.Example
    
#>

function Set-AccountEnabledOnLicenceStatusInGroup {
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
        [switch]
        $LicenceStatus,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify account action if required licence status is not found"
        )]
        [switch]
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
            
            # Check licence for each member
            $UserLicenceCheck = foreach ($Member in $AzureADGroupMembers){
                $UserServicePlans = Get-AzureADUserLicenseDetail -ObjectId $Member.ObjectId `
                    | Select-Object -ExpandProperty ServicePlans
                
                # Filter to specific service plan
                $UserServicePlan = $UserServicePlans | Where-Object ServicePlanId -eq $ServicePlanId
                
                # Build object properties
                $ObjectProperties = @{
                    ObjectID = $Member.ObjectId
                    DisplayName = $Member.DisplayName
                    UserPrincipalName = $Member.UserPrincipalName
                    ServicePlanId = $ServicePlanId
                }
                # If service plan exists, append to object
                if ($UserServicePlan){
                    $ObjectProperties += @{
                        Licence = $UserServicePlan.ServicePlanName
                        Status = $UserServicePlan.ProvisioningStatus
                    }
                }
                # If service plan does not exist, append error
                else {
                    $ObjectProperties += @{
                        Licence = $NoLicence
                        Status = $NoLicenceStatus
                    }
                }

                # Create new object per member with licence status information
                New-Object psobject -Property $ObjectProperties
            }

            # For any user without a successfully provisioned licence, block account for safety
            $UnlicencedUsers = $UserLicenceCheck.status -ne $LicenceStatus
            if ($UnlicencedUsers){
                $UnlicencedUsers | ForEach-Object {
                    Set-AzureADUser -ObjectID $_.ObjectId -AccountEnabled $AccountEnabled
                }
            }
        }
        Catch {
            Write-Error -Message $_.exception

        }
    }
    End {

    }
}