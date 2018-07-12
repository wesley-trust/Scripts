<#
#Script name: Get Partner Center Customer Subscriptions
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 2
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
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Specify a PowerShell credential object"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Subscription name"
        )]
        [string]
        $OfferName,
        [Parameter(
            Mandatory = $false
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
            if ($TenantID) {
                $customers = Get-PCCustomer -Tenantid $tenantid
            }
            else {
                $Customers = Get-PCCustomer -ResultSize 500
            }
            
            # If there are customers
            if ($customers) {
                
                # For each customer
                $SubscriptionCustomers = foreach ($Customer in $Customers) {

                    # Get all subscriptions
                    $Subscriptions = Get-PCSubscription -tenantid $Customer.id | Where-Object offerName -eq $OfferName
                    
                    # For each subscription
                    foreach ($Subscription in $Subscriptions) {
                        [pscustomobject]$ObjectProperties = @{
                            TenantID       = $Customer.id
                            Customer       = $Customer.CompanyProfile.CompanyName
                            SubscriptionId = $Subscription.id
                            Name           = $Subscription.friendlyname
                            OfferName      = $Subscription.offername
                            OfferID        = $Subscription.offerid
                            State          = $Subscription.status
                        }
                    }
                }
                if ($SubscriptionCustomers) {
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