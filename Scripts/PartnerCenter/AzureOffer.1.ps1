<#
#Script name: Create Microsoft Azure CSP offer
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 2
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
        Mandatory=$false,
        Position = 0,
        HelpMessage="Subscription name"
    )]
    [string]
    $friendlyName = "Microsoft Azure",
    [Parameter(
        Mandatory=$false
    )]
    [int]
    $Quantity = 3,
    [Parameter(
        Mandatory=$true
    )]
    [string]
    $tenantid,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $OfferID = "MS-AZR-0146P",
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $CountryID = "US"
)

Begin {
    try {

        # Connect to Partner Center
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Authentication"
        . .\Connect-PartnerCenter.ps1

        Connect-PartnerCenter -Credential $Credential | Out-Null

        # Required Module Classes
        $Module = "PartnerCenterModule"

        # Import Module Classes
        $scriptBody = "using module $Module"
        $script = [ScriptBlock]::Create($scriptBody)
        . $script

    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # Get Customer
        $customer = Get-PCCustomer -tenantid $tenantid

        # Get Offer
        $offer = Get-PCOffer -countryid $CountryID -offerid $OfferID

        # Create the OrderLineItem
        $lineItems = @()
        $lineItems += [OrderLineItem]::new()
        $lineItems[0].LineItemNumber = 0
        $lineItems[0].FriendlyName = $FriendlyName
        $lineItems[0].OfferId = $offer.id
        $lineItems[0].Quantity = $Quantity

        # Send order
        New-PCOrder -tenantid $customer.id -LineItems $lineItems
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}