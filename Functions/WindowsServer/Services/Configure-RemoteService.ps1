<#
#Script name: Create new service on remote computers
#Creator: Wesley Trust
#Date: 2017-09-05
#Revision: 5
#References:
#ToDo
    .Write error logging to file
    .Pipeline input for servers
    .Force parameter for install
    .Ability to override server connection checks?

.Synopsis
    Function that installs a service.
.Description

.Example
    New-RemoteService

#>

function New-RemoteService {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Specify a computer name, multiple computers can be in array format or comma separated",
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
        $Credential,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceEXE,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceConfig,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceInstallLocation,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ArgumentList
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

            # For each computer, configure service
            foreach ($Computer in $ComputerName) {
                
                # Create new session
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                        
                # Run command in remote session to install
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                                
                    # Check if service is installed
                    $Service = Get-Service $Using:ServiceName -ErrorAction Stop
                                
                    # Check if service is running
                    If ($Service | Where-Object Status -eq "Running") {
            
                        #Service already installed and running
                        Write-Host ""
                        Write-Output "Service already installed and running on"$using:Server.DNSHostName | Tee-Object -Append -FilePath .\RunningLog.txt
                    }
                    Else {
                        #Try starting service
                        $Service = $Service | Start-Service -PassThru -ErrorAction Stop
                                        
                    }
                }
            }
            
            # Get file, pipe to copy to remote session
            Get-ChildItem $ServiceEXE | Copy-Item -Destination $env:SystemDrive\ -ToSession $Session -Force -ErrorAction Stop
            
            # Run command in remote session to install
            Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                                
                #E xecute installer
                Set-Location $env:SystemDrive\
                Start-Process "msiexec.exe" -ArgumentList $Using:ArgumentList -Wait
            }
                            
            # Get file, pipe to remote session
            Get-ChildItem $ServiceConfig | Copy-Item -Destination $ServiceInstallLocation -ToSession $Session -Force
                            
            # Run command in remote session
            Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                                
                # Restart Service
                Restart-Service $Using:ServiceName -WarningAction Stop
                                
                # Clean up
                Remove-Item $Using:ServiceEXE
            }

            #Remove session
            Remove-PSSession -Session $Session
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