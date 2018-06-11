<#
#Script name: Get remote computers from a DC and OU
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 4
#References:

.Synopsis
    Function that connects remotely to a domain controller, and gets the computers within an OU if specified.
.Description
    Multiple computer names of domain controllers and OUs can be specified
.Example
    Get-RemoteADComputer -ComputerName $ComputerName -OU $OU
.Example
    
#>

Function Get-RemoteADComputer {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            HelpMessage = "Specify the Computer Name of the domain controller, multiple DCs can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $ComputerName,
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Specify OU in DN format, multiple OUs can be in array format or comma separated",
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $OU,
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
            $OU = $OU.Split(",")
            $OU = $OU.Trim()

            # Foreach computer, store output in variable
            $SessionADComputer = foreach ($Computer in $ComputerName) {
                
                # Create remote PowerShell session to DC
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential

                # Invoke remote command within session
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
    
                    # If an OU parameter exists
                    if ($Using:OU) {

                        # Foreach OU search within that OU
                        foreach ($OU in $Using:OU) {
                            Get-ADComputer -Filter * -SearchBase $OU
                        }
                    }

                    #  Or return all
                    else {
                        Get-ADComputer -Filter *
                    }
                }

                # Remove session
                Remove-pssession -Session $Session
            }
            
            return $SessionADComputer
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