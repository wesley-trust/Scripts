<#
#Script name: Move AD Objects to new OU
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 2
#References:

.Synopsis
    Function that connects to a domain controller, and moves objects to a new OU.
.Description
    Multiple domain controllers can be specified, as well as objects to move.
.Example
    Move-RemoteADObject -DC $DC -SourceOU $SourceOU -DestinationOU $DestinationOU

.Example

#>

Function Move-RemoteADObject {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            HelpMessage = "Specify the domain controller, multiple DCs can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $DC,
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Optionally specify an object to move, multiple objects can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $ObjectName,
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Enter in DN format",
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $SourceOU,
        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Enter in DN format",
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $DestinationOU,
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
            $DC = $DC.Split(",")
            $DC = $DC.Trim()
            $ObjectName = $ObjectName.Split(",")
            $ObjectName = $ObjectName.Trim()

            # For each server
            $RemoteADObject = foreach ($Server in $DC) {
    
                # Create remote PowerShell session to DC
                $Session = New-PSSession -ComputerName $Server -Credential $Credential

                # Invoke remote command within open session
                $RemoteADObject = Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                    
                    # If there are objects specified
                    If ($ObjectName) {
                        
                        # Move each object to the new OU
                        foreach ($Object in $ObjectName) {
                            Get-ADObject -Filter {Name -eq $Object} | Move-ADObject -TargetPath $Using:DestinationOU
                        }
                    }
                    Else {
                        
                        # Move all computers within source OU to destination OU
                        Get-ADObject -Filter * -SearchBase $Using:SourceOU | Move-ADObject -TargetPath $Using:DestinationOU
                    }
                }

                # Remove session
                Remove-pssession -Session $Session
            }
            Return $RemoteADObject
        }
        catch {

        }
    }
    End {
        Try {

        }
        catch {
            
        }
    }
}