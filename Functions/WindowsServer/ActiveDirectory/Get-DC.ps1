<#
#Script name: Get domain controller from domain name
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 3
#References:

.Synopsis
    Script that resolves a domain controller from a domain name.
.Description
    Script that resolves a domain controller from a domain name, when using an AD integrated DNS zone for the domain.
.Example
    Specify the fully qualified Domain Name (DNSDomain), multiple domains can be in array format or comma separated.
.Example

#>

function Get-DC {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            HelpMessage = "Enter the FQDN, multiple domains can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DNSDomain
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
            # Split and trim input
            $DNSDomain = $DNSDomain.Split(",")
            $DNSDomain = $DNSDomain.Trim()

            # For each domain, resolve a domain controller
            $DC = foreach ($Domain in $DNSDomain) {

                # Build custom object
                $ObjectProperties = @{
                    DNSDomain = $Domain
                }
                
                # Get start of authority of domain
                $SOA = Resolve-DnsName $Domain -Type SOA

                # If record returns
                if ($SOA) {
                    $ObjectProperties += @{
                        ResolvedStatus = "Success"
                        PrimaryServer  = $SOA.PrimaryServer
                        IP4Address     = $SOA.IP4Address
                    }
                    
                    # Test ping to server
                    $PrimaryServerTest = Test-Connection $SOA.primaryserver -Count 1 2> Out-Null

                    # If successful
                    if ($PrimaryServerTest) {
                        $ObjectProperties += @{
                            PingStatus   = "Success"
                            ResponseTime = $PrimaryServerTest.responsetime
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            PingStatus = "Failed"
                        }
                    }
                }

                # Create object
                New-Object -TypeName psobject -Property $ObjectProperties
            }

            return $DC
        }
        catch {
            Write-Error -Message $_.Exception

        }
    }
    End {
        try {
        
        }
        catch {
            Write-Error -Message $_.Exception

        }
    }
}