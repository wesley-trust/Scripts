<#
#Script name: Run server command template
#Creator: Wesley Trust
#Date: 2017-08-31
#Revision:
#References:

.Synopsis
    Template that calls a function that tests the connection to remote servers, then executes a command.
.Description
    Template that calls a function that tests the connection to remote servers,
    then executes a command on successful servers after confirmation.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    

#>

#Include Functions

function Test-PipelineArray () {
    #Parameters
    Param(
        
    #Servers
        [Parameter(
            Mandatory=$false,
            Position=0,
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DNSHostName
    )
    Begin {
        Write-Host "Test-PipelineArray Function"
    }
    
    Process
    {
        foreach ($Server in $_)
        {
            $Server.DNSHostName
        }
    }
}