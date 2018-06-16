<#
#Script name: User SKU status
#Creator: Wesley Trust
#Date: 2018-06-16
#Revision: 1
#References: 
.Synopsis
    Function to get the Sku status of users, allows specific users or skus to be specified.
.Description
    By default only returns users and skus that are assigned.
.Example
    Get-AzureADUserSkuStatus
#>
Function Get-AzureADUserSkuStatus {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the UPN of user to check, multiple UPNs can be comma separated or in an array",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $UserPrincipalName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the SKU id to check, multiple SKUs can be comma separated or in an array",
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $SkuId,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to include users with unassigned skus",
            ValueFromPipeLineByPropertyName = $true
        )]
        [switch]
        $IncludeUnassignedUser,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to include unassigned subscribed skus",
            ValueFromPipeLineByPropertyName = $true
        )]
        [switch]
        $IncludeUnassignedSku
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.exception
        }
    }

    Process {
        try {
            
            # If specific users exist to check, else check all users
            if ($UserPrincipalName) {
    
                # Split and trim input
                $UserPrincipalName = $UserPrincipalName.Split(",")
                $UserPrincipalName = $UserPrincipalName.Trim()

                # Get Members of Azure AD Group
                $AzureADUser = foreach ($UPN in $UserPrincipalName) {
                    Get-AzureADUser -Filter "UserPrincipalName eq '$UPN'"
                }
            }
            else {
                $AzureADUser = Get-AzureADUser -All $true
            }

            # If switch is not true, filter to users with assigned licences only
            if (!$IncludeUnassignedUser){
                
                # Filter to licenced users
                $AzureADUser = $AzureADUser | Where-Object {$_.AssignedLicenses}
            }

            # User check
            if (!$AzureADUser) {
                $ErrorMessage = "No users returned to check sku status"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # Get all subscribed skus
            $SubscribedSku = Get-AzureADSubscribedSku

            # If specific skus are present
            if ($SkuId) {
                
                # Split and trim input
                $SkuId = $SkuId.Split(",")
                $SkuId = $SkuId.Trim()
            }
            elseif ($IncludeUnassignedSku) {
                
                # Include all subscribed sku ids to check
                $SkuId = $SubscribedSku.skuid
            }
            else {
                
                # Get unique skus assigned to users
                $SkuId = $AzureADUser.AssignedLicenses.SkuId | Select-Object -Unique
            }

            # For each user
            $UserSkuStatus = foreach ($User in $AzureADUser) {
    
                # Build object properties
                $ObjectProperties = [ordered]@{
                    DisplayName = $User.DisplayName
                    UserPrincipalName = $User.UserPrincipalName
                }
    
                # For each assigned sku
                foreach ($Sku in $SkuId) {
        
                    # Get the specific sku details
                    $SkuDetail = $SubscribedSku | Where-Object {$_.skuid -eq $Sku}
        
                    # If that sku, is in the list of skus assigned to the user, append true, else null
                    if ($Sku -in $User.AssignedLicenses.SkuId) {
                        $ObjectProperties += @{
                            $SkuDetail.skupartnumber = $true
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            $SkuDetail.skupartnumber = $null
                        }
                    }
                }
    
                # Create object per user with properties
                New-Object -TypeName psobject -Property $ObjectProperties
            }

            return $UserSkuStatus
        }
        catch {
            Write-Error -Message $_.exception
        }
    }

    End {
        try {

        }
        catch {
            Write-Error -Message $_.exception
        }
    }
}