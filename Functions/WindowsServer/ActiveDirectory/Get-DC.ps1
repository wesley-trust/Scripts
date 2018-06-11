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
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DNSDomain,
        [Parameter(
            HelpMessage = "Specify whether to ping test DC",
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [bool]
        $TestConnection
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
                
                # Get start of authority of domain
                $SOA = Resolve-DnsName $Domain -Type SOA

                # If record returns
                if ($SOA) {
                    $ObjectProperties += @{
                        Domain      = $Domain
                        ResolvedStatus = $true
                        ComputerName  = $SOA.PrimaryServer
                        IP4Address     = $SOA.IP4Address
                    }

                    # If true, test ping to server
                    if ($TestConnection) {

                        $TestConnection = Test-Connection $Computer `
                            -Count 1 `
                            -ErrorVariable PingError `
                            2> Out-Null

                        # If successful, return positive, else negative
                        if ($PingStatus) {
                            $ObjectProperties += @{
                                PingStatus = $true
                                ResponseTime = $TestConnection.responsetime
                            }
                        }
                        else {
                            $ObjectProperties += @{
                                PingStatus = $false
                                PingError = $PingError.Exception
                            }
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