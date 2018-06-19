<#
#Script name: Create Microsoft Azure CSP offer
#Creator: Wesley Trust
#Date: 2018-04-05
#Revision: 3
#References: 

.Synopsis
    
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        Position = 0,
        HelpMessage="Specify a PowerShell credential object"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory=$true,
        Position = 0,
        HelpMessage="Subscription name"
    )]
    [string]
    $friendlyName,
    [Parameter(
        Mandatory=$true
    )]
    [int]
    $Quantity,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $tenantid,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $CustomerName,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $TenantDomain,
    [Parameter(
        Mandatory=$true
    )]
    [string]
    $OfferID,
    [Parameter(
        Mandatory=$true
    )]
    [string]
    $CountryID,
    [Parameter(
        Mandatory=$false
    )]
    [switch]
    $force
)

Begin {
    try {
        
        # Load functions
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
        . .\Invoke-DependencyCheck.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Authentication"
        . .\Connect-PartnerCenter.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Customer"
        . .\Find-PCCustomer.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Order"
        . .\New-PCOrderItem.ps1
        
        # Required Module
        $Module = "PartnerCenterModule"
        
        Invoke-DependencyCheck -Modules $Module

        # Import Module Classes
        $scriptBody = "using module $Module"
        $script = [ScriptBlock]::Create($scriptBody)
        . $script
        
        # Connect to Partner Center
        Connect-PartnerCenter -Credential $Credential | Out-Null

    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # Get Customer
        if ($TenantID){
            $customer = Get-PCCustomer -tenantid $tenantid
        }
        else {
            $customer = Find-PCCustomer -Name $CustomerName -Domain $TenantDomain
        }

        if ($customer){

            # Get Offer
            $offer = Get-PCOffer -countryid $CountryID -offerid $OfferID

            if ($offer){

                # Create the OrderLineItem
                $lineItems = @()
                $lineItems += [OrderLineItem]::new()
                $lineItems[0].LineItemNumber = 0
                $lineItems[0].FriendlyName = $FriendlyName
                $lineItems[0].OfferId = $offer.id
                $lineItems[0].Quantity = $Quantity

                # Send order
                if (!$Force){
                    $Choice = $Null
                    $Choice = Read-Host "Do you want to order $Quantity of $friendlyName ? (Y/N)"
                    if ($Choice -eq "Y"){
                        $Force = $True
                    }
                }
                if ($Force){
                    New-PCOrder -tenantid $customer.id -LineItems $lineItems
                }
                else {
                    $ErrorMessage = "Unable to order, confirmation was not received, or Force was not specified"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
            else {
                $ErrorMessage = "No Parnter Center offer that matches $OfferId in country $CountryID"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
        else {
            $ErrorMessage = "No customer returned, unable to order without a customer"
            Write-Error $ErrorMessage
            throw $ErrorMessage
        }
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}