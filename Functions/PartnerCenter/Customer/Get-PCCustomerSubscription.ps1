<#
#Script name: Get Partner Center Customer Subscriptions
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 1
#References: 

.Synopsis
    Gets specific, or all customers' subscriptions, supports offer name parameter
.Description

.Example
    
.Example
    
#>
function Get-PCCustomerSubscription() {
    [cmdletbinding()]
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
        $OfferName,
        [Parameter(
            Mandatory=$false
        )]
        [string]
        $tenantid
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
            # Get Customer
            if ($TenantID){
                $customers = Get-PCCustomer -Tenantid $tenantid
            }
            else {
                $Customers = Get-PCCustomer -all
            }
            
            # If there are customers
            if ($customers){
                # For each customer
                $SubscriptionCustomers = $Customers | ForEach-Object {
                    $TenantID = $_.id
                    $CustomerName = $_.CompanyProfile.CompanyName
                    # Get all subscriptions
                    $Subscription = Get-PCSubscription -tenantid $TenantID -all | Where-Object offerName -eq $OfferName
                    # For each subscription
                    $Subscription | ForEach-Object {
                        $ObjectProperties = @{
                            TenantID = $tenantid
                            Customer = $CustomerName
                            SubscriptionId = $_.id
                            Name = $_.friendlyname
                            OfferName = $_.offername
                            OfferID = $_.offerid
                            State = $_.status
                        }
                        # Create new object per subscription
                        New-Object psobject -Property $ObjectProperties
                    }
                }
                if ($SubscriptionCustomers){
                    return $SubscriptionCustomers
                }
                else {
                    $ErrorMessage = "No customers have $OfferName"
                    Write-Error $ErrorMessage
                }
            }
            else {
                $ErrorMessage = "No customer returned"
                Write-Error $ErrorMessage
            }
        }
        Catch {
            Write-Error -Message $_.exception
        }
    }
    End {
        
    }
}