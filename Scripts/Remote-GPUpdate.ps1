<#

#Script name: Script to execute gpupdate remotely on computers
#Creator: Wesley Trust
#Date: 2017-11-14
#Revision: 1
#References: 

.Synopsis
    A script that resolves the domain controller, gets computers within an OU and executes gpupdate on each remotely.
.DESCRIPTION

#>

# Parameters
Param(
    [Parameter(
        Mandatory=$True,
        HelpMessage="Enter the fully qualified domain name"
    )]
    [String]
    $Domain,
    
    [Parameter(
        Mandatory=$True,
        HelpMessage="Enter the OU to select computers"
    )]
    [String]
    $OU
)

# Authentication Variable
$Credential = Get-Credential

try {
    
    # Update variable with the start of authority object
    $Domain = Resolve-DnsName $Domain -Type SOA

    # Create session to primary server of domain
    $Session = New-PSSession -ComputerName $Domain.PrimaryServer -Credential $Credential

    # Invoke remote command within open session
    $Computers = Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
        
                #Get Servers within OU
                Get-ADComputer -Filter * -SearchBase $OU
    }

    # Remove session
    Remove-PSSession -Session $Session

    # For each computer in variable
    foreach ($Computer in $Computers){

        # Create session
        $Session = New-PSSession -ComputerName $Computer.dnshostname -Credential $Credential

        # Run command in remote session for server
        Invoke-Command -Session $Session -ScriptBlock {

        gpupdate /force

        }

        # Remove session
        Remove-PSSession -Session $Session

    }
}

catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}