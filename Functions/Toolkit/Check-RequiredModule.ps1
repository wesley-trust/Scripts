<#
#Script name: Check-RequiredModule
#Creator: Wesley Trust
#Date: 2017-12-04
#Revision: 1
#References: 

.Synopsis
    Function that checks if a required module is installed, and installs if nessessary.
.Description

.Example
    Check-RequiredModule -Modules "AzureAD"
.Example
    
#>

function Check-RequiredModule() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the module"
        )]
        [string[]]
        $Modules
    )

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
            # If no modules are specified
            while (!$Modules) {
                $Modules = Read-Host "Enter module name(s), comma separated, to check or install"
            }

            # Clean input
            $Modules = $Modules.Split(",")
            $Modules = $Modules | ForEach-Object {$_.Trim()}

            foreach ($Module in $Modules){
                # Check if module is installed
                $ModuleCheck = Get-Module -ListAvailable | Where-Object Name -eq $Module
                
                # If not installed, install the module
                if (!$ModuleCheck){
                    Install-Module -Name $Module -AllowClobber -Force
                }
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}