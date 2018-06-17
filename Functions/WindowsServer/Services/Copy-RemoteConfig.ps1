<#
#Script name: Configure service
#Creator: Wesley Trust
#Date: 2017-09-05
#Revision: 3
#References:
#ToDo
    .Write error logging to file
    .Pipeline input for servers
    .Force parameter for install
    .Ability to override server connection checks?

.Synopsis
    Function that calls a function that tests servers, within an OU, can be connected to remotely, and installs a service.
.Description
    Function that calls a function that tests servers, within an OU, can be connected to remotely, and installs a service,
    logging success and failures in a text file.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Service -Domain $Domain -OU $OU -ServiceEXE $ServiceEXE -ServiceName $ServiceName -ServiceConfig $ServiceConfig -ServiceInstallLocation $ServiceInstallLocation

#>

function Copy-RemoteConfig() {
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
        $ServiceInstallLocation
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
                $Session = New-PSSession -ComputerName $Computer.DNSHostName -Credential $Credential -ErrorAction Stop
                
                # Get file, pipe to remote session
                Get-ChildItem $ServiceConfig | Copy-Item -Destination $ServiceInstallLocation -ToSession $Session -Force
            
                # Run command in remote session
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                
                    #Restart Service
                    Restart-Service $Using:ServiceName -WarningAction Stop
                }
            
                # Remove session
                Remove-PSSession -Session $Session

                # Write Output
                Write-Host ""
                Write-Output "Successfully copied config file to "$Computer.DNSHostName | Tee-Object -FilePath .\Success.log

            }
        }
        catch {
            Write-Error -Message $_.Exception | Tee-Object -FilePath .\errorlog.txt
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