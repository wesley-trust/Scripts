<#

#Script name: Script to execute gpupdate remotely on computers
#Creator: Wesley Trust
#Date: 2017-11-14
#Revision: 2
#References: 

.Synopsis
    A script that resolves the domain controller, gets computers within an OU then executes gpupdate on each remotely.
.DESCRIPTION
    A script that executes a function that resolves the domain controller,
    (defaults to current DNS domain, assumes domain controller is DNS server),
    gets computers within an OU on that domain controller, then executes gpupdate on each computer remotely.
#>

Function Invoke-Remote-GPUpdate () {

    # Parameters
    Param(
        [Parameter(
            Mandatory=$True,
            HelpMessage="Enter the fully qualified domain name"
        )]
        [String]
        $Domain = $ENV:USERDNSDOMAIN,
        
        [Parameter(
            Mandatory=$True,
            HelpMessage="Enter the OU (in DN format) to select computers"
        )]
        [String]
        $OU
    )

    begin {
        try {
            # Authentication Variable
            $Credential = Get-Credential
        }
        catch {
            Write-Error $_
            throw $_
        }
    }

Process {

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

        if (!$Computers){
            $ErrorMessage = "No computers returned"
            Write-Error $ErrorMessage
            throw $ErrorMessage
        }

        $Computers = foreach ($Computer in $Computers){
            
            # Try connecting to WinRM
            $Test = Test-WSMan `
                        -ComputerName $Computer.DNSHostName `
                        -Authentication Default `
                        -Credential $Credential `
                        -ErrorAction SilentlyContinue

            if ($Test){
                
                #Create object property variable
                $ObjectProperties = @{
                    DNSHostName = $Computer.DNSHostName
                    Status = "Success"
                }
            }

            # Create a new object, with the properties
            New-Object psobject -Property $ObjectProperties
        }

        if (!$Computers){
            $ErrorMessage = "No computers can be connected to"
            Write-Error $ErrorMessage
            throw $ErrorMessage
        }

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
        
        # Catch exceptions
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

end {

}

# Execute Script, defaults to current user DNS domain
Invoke-Remote-GPUpdate