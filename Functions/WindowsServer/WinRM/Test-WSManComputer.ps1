<#
#Script name: Test connection to server
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 5
#References:

.Synopsis
    Function that tests whether a computer can be resolved and connected to remotely.

.Description
    Accepts multiple computers in array or comma separated, returns test status as an object, if unable to connect remotely, captures error and ping test.

.Example
    Test-WSManComputer -ComputerName $ComputerName

.Example
    
#>

function Test-WSManComputer {
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
            $WSManComputer = foreach ($Computer in $ComputerName) {
                
                # Resolve DNS
                $ResolvedStatus = Resolve-DnsName $Computer

                # If successful, build object
                if ($ResolvedStatus) {
                    $ObjectProperties = @{
                        Computer       = $Computer
                        ResolvedStatus = $true
                    }

                    # Test WSMan connection                    
                    $WSManStatus = Test-WSMan `
                        -ComputerName $Computer `
                        -Authentication Default `
                        -Credential $Credential `
                        -ErrorVariable WSManStatusError `
                        2> Out-Null

                    # If successful, append to object
                    if ($WSManStatus) {
                        $ObjectProperties += @{
                            WSManStatus = $true
                        }
                    }
                    
                    # If unsuccessful, append error
                    else {
                        $ObjectProperties += @{
                            WSManStatus      = $false
                            WSManStatusError = $WSManStatusError.Exception
                        }

                        # Ping computer to test if alive
                        $PingStatus = Test-Connection $Computer -Count 1 2> Out-Null
                        
                        # If successful, return positive, else negative
                        if ($PingStatus) {
                            $ObjectProperties += @{
                                PingStatus = $true
                            }
                        }
                        else {
                            $ObjectProperties += @{
                                PingStatus = $false
                            }
                        }
                    }

                    # Create a new object, with the properties
                    New-Object psobject -Property $ObjectProperties
                }
            }
            return $WSManComputer
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