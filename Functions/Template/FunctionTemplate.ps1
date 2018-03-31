<#
#Script name: FunctionName
#Creator: Wesley Trust
#Date: YYYY-MM-DD
#Revision: X
#References: 

.Synopsis
    
.Description

.Example
    
.Example
    
#>

function FunctionName() {
    Param(
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a PowerShell credential object"
        )]
        [pscredential]
        $Credential
    )
pscredential
    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {

        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}