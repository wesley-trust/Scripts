<#
#Script name: Create Microsoft Azure CSP offer
#Creator: Wesley Trust
#Date: 2018-04-05
#Revision: 1
#References: 

.Synopsis
    
.Description

.Example
    
.Example
    
#>

# Load class
using module PartnerCenterModule

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
        Mandatory=$true
    )]
    [int]
    $Quantity,
    [Parameter(
        Mandatory=$true
    )]
    [string]
    $cspAppID,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $cspDomain,
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
        
        # Required Module
        $Module = "PartnerCenterModule"

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
        . .\Check-RequiredModule.ps1

        Check-RequiredModule -Modules $Module
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        # If there are no credentials, request these
        if (!$Credential){
            $Credential = Get-Credential -Message "Enter Partner Center credentials"
        }

        # If no CSP Domain is specified, get domain from credential username (and assume is correct)
        if (!$cspDomain){
            $cspDomain = ($Credential.UserName).Split("@")[1]
        }

        # Add Authentication
        Add-PCAuthentication -cspAppID $cspAppID -credential $credential -cspDomain $cspDomain
        
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