<#
#Script name: Move servers to new OU
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: UNFINISHED
#References:

.Synopsis
    Script that calls a function to resolve the domain controller, then asks whether to move the servers to a new OU.
.Description
    Script that calls a function to resolve the domain controller, then asks whether to move the servers to a new OU.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU, MoveOU) by distinguished name (DN).
    MoveOU is an optional parameter.
    Configure-Drive -Domain $Domain -OU $OU -MoveOU $MoveOU
.Example
    

#>

#Include Functions
. .\Get-DC.ps1
. .\Get-Server.ps1

Function Move-ServerOU () {
    #Parameters
    Param(
        #Request Domain
        [Parameter(
            Mandatory=$false,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU,

        #Request New OU to move servers to
        [Parameter(
            Mandatory=$true,
            Position=3,
            HelpMessage="Enter in DN format")]
        [ValidateNotNullOrEmpty()]
        [String]
        $MoveOU,

        #Servers
        [Parameter(
            Mandatory=$false,
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DNSHostName
        )
        
        #If there are no credentials, prompt for credentials
        if ($Credential -eq $null) {
            Write-Output "Enter credentials for remote computer"
            $Credential = Get-Credential
        }
       
        #Get Servers
        if ($Domain -ne $null -and $OU -ne $Null){
            $ServerGroup = Get-Server -Domain $Domain -OU $OU
        }
        else {
            $ServerGroup = Get-Server
        }

        #Check server name(s) returned
        if ($ServerGroup -eq $null){
            Write-Error 'No servers returned.' -ErrorAction Stop
        }

        #List server names returned
        Write-Host ""
        Write-Host "Servers:"
        Write-Host ""
        #Write server name per line
        foreach ($Server in $ServerGroup){
            Write-Host $Server.name
        }
        Write-Host ""
    
    #Pipline compatible input
    Begin {

    }
    Process {

        #Prompt for input
        while ($choice -notmatch "[y|n]"){
            $choice = read-host "Move servers to new OU? (Y/N)"
            
        }
        if ($choice -eq "y"){
            
            #Request new OU if parameter not specified
            If ($MoveOU -eq $null){
                $MoveOU = Read-Host "Specify OU to move servers to"
            }
            
            #Get Domain controller
            $DC = Get-DC -Domain $Domain

            #Try connecting to domain controller
            try {
                #Create PowerShell session
                $Session = New-PSSession -ComputerName $DC -Credential $Credential
            }
            catch {
                Write-Error "Failed to remotely connect to $DC" -ErrorAction Stop
            }

            #Invoke remote command within open session
            $ServerGroup = Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                
                #Get computer objects and move to new OU
                If ($Using:DNSHostName -eq $null){
                    Get-ADComputer -Filter * -SearchBase $Using:OU | Move-ADObject -TargetPath $Using:MoveOU
                }
                Else {
                    foreach ($DNSHostName in $_){
                        Get-ADComputer -Filter {Name -eq $_} | Move-ADObject -TargetPath $Using:MoveOU
                    }

                }
                #Get servers to store in variable
                Get-ADComputer -Filter * -SearchBase $Using:MoveOU
            }

            #Remove session
            Remove-pssession -Session $Session

            #Check if servers are returned
            if ($ServerGroup -eq $Null) {
                Write-Error "No servers returned." -ErrorAction Stop
            }
            else {
                #Return servers
                Write-Host "Servers moved to new OU"
                Return $ServerGroup

            }
        }
        else {  
            Write-Host ""
            write-output "Servers will remain in current OU"
            Return $ServerGroup
        }
    }
    End{

    }
}