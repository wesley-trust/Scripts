<#
#Script name: Create PC Order Item
#Creator: Wesley Trust
#Date: 2018-04-09
#Revision: 1
#References: 

.Synopsis
    
.Description

.Example
    
.Example
    
#>
function New-PCOrderItem() {
    [CmdletBinding()]
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
        $OfferID,
        [Parameter(
            Mandatory=$false
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

        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }

    Process {
        try {

            # Verify Customer
            $customer = Get-PCCustomer -tenantid $tenantid
            if ($customer){

                # Verify offer
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
                    $ErrorMessage = "No Partner Center offer that matches $OfferId in country $CountryID"
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
}