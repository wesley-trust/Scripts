<#
#Script name: Test connection to remote computer
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 6
#References:

.Synopsis
    Function that tests whether a computer can be resolved, pinged and connected to remotely.

.Description
    Accepts multiple computers in array or comma separated, returns test status as an object and captures error.

.Example
    Test-RemoteComputer -ComputerName $ComputerName

.Example
    
#>

function Test-RemoteComputer {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            HelpMessage = "Enter the Computer Name, multiple computers can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $ComputerName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Begin {
        try {

            # If no credentials, request them
            if (!$Credential) {
                $Credential = Get-Credential -Message "Enter credential for remote computer"
            }
        }
        catch {
            Write-Error -Message $_.Exception
        }
    }

    Process {
        try {
            # Split and trim input
            $ComputerName = $ComputerName.Split(",")
            $ComputerName = $ComputerName.Trim()

            # Foreach computer
            $TestComputer = foreach ($Computer in $ComputerName) {
                
                # Resolve DNS
                $ResolveDNS = Resolve-DnsName $Computer

                # If successful, build object
                if ($ResolveDNS) {
                    $ObjectProperties = @{
                        Computer       = $Computer
                        ResolvedStatus = $true
                    }

                    # Test WSMan connection                    
                    $TestWSMan = Test-WSMan `
                        -ComputerName $Computer `
                        -Authentication Default `
                        -Credential $Credential `
                        -ErrorVariable WSManError `
                        2> $null

                    # Append result
                    if ($TestWSMan) {
                        $ObjectProperties += @{
                            WSManStatus = $true
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            WSManStatus      = $false
                            WSManError = $WSManStatusError.Exception
                        }
                    }

                    # Ping computer to test if alive
                    $TestConnection = Test-Connection $Computer `
                        -Count 1 `
                        -ErrorVariable PingError `
                        2> $null
                        
                    # If successful, return positive, else negative
                    if ($TestConnection) {
                        $ObjectProperties += @{
                            PingStatus = $true
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            PingStatus = $false
                            PingError = $PingError.Exception
                        }
                    }
                }

                # Create a new object, with the properties
                New-Object psobject -Property $ObjectProperties
            }
            return $TestComputer
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