<#
#Script name: Check-RequiredModule
#Creator: Wesley Trust
#Date: 2017-12-04
#Revision: 2
#References: 

.Synopsis
    Function that checks if a required module is installed, and installs if nessessary.
.Description

.Example
    Check-RequiredModule -Modules "AzureAD"
.Example
    
#>

function Check-RequiredModule() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the PSDesktop module name(s)"
        )]
        [string[]]
        $Modules,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the PSCore module name(s)"
        )]
        [string[]]
        $ModulesCore,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to update module if installed"
        )]
        [switch]
        $Update
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

            # Check for PowerShell Core
            if ($PSVersionTable.PSEdition -eq "Core"){
                # If true, update module with core version
                $Modules = $ModulesCore
            }

            # Check if session is elevated
            $Elevated = ([Security.Principal.WindowsPrincipal] `
                [Security.Principal.WindowsIdentity]::GetCurrent() `
                ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            # If Elevated, install for all users, otherwise, current user.
            if ($Elevated){
                $Scope = "AllUsers"
            }
            else {
                $Scope = "CurrentUser"
            }

            # If no modules are specified
            while (!$Modules) {
                $Modules = Read-Host "Enter module name(s), comma separated, to check to install"
            }

            # Clean input and create array
            $Modules = $Modules.Split(",")
            $Modules = $Modules | ForEach-Object {$_.Trim()}

            foreach ($Module in $Modules){
                # Check if module is installed
                Write-Host "`nChecking if required module $Module is installed`n"
                $ModuleCheck = Get-Module -ListAvailable | Where-Object Name -eq $Module
                
                # If not installed, install the module
                if (!$ModuleCheck){
                    write-Host "Installing required module $Module for $Scope"
                    Install-Module -Name $Module -AllowClobber -Force -Scope $Scope -ErrorAction Stop
                }
                else {
                    if ($Update){
                        if (!$Elevated){
                            if ($ModuleCheck.path -like "*Program Files*"){
                                $Update = $false
                                $WarningMessage = "Skipping module update, rerun as an administrator to update this module"
                                Write-Warning $WarningMessage
                            }
                        }
                        if ($Update){
                            write-Host "Checking for update to module $Module`n"
                            Update-Module -Name $Module
                        }
                    }
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