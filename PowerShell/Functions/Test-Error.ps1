<#
#Script name: Configure service
#Creator: Wesley Trust
#Date: 2017-09-05
#Revision: 2
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

#Include Functions
. .\Test-Server.ps1

function Test-Error() {

    Begin {
    
    }
    
    Process {
        Try{
            Test-Connection -ComputerName blah -ErrorAction Stop -Count 1
        }
        Catch {
            Write-Host ""
            Write-Output $_.Exception.Message | Tee-Object -FilePath .\errorlog.txt
        }
    }
    End {
        
    }
}