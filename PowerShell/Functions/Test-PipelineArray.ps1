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
        
        #Server host name
        [Parameter(
            Mandatory=$false,
            Position=0,
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DNSHostName,
        
        #Server connection status
        [Parameter(
            Mandatory=$false,
            Position=0,
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Success
    )
    Begin {
        Write-Host "Test-PipelineArray Function"
    }
    
    Process
    {
        #Reconstitute object from pipeline
        $ServerGroup = foreach ($Server in $_)
        {
            $ObjectProperties = @{
                DNSHostName  = $Server.DNSHostName
                Status = $Server.Status
            }
            New-Object psobject -Property $ObjectProperties
            
        }
    Return $ServerGroup
    }
}