<#
#Script name: Check-RequiredModule
#Creator: Wesley Trust
#Date: 2017-12-04
#Revision: 3
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
            Mandatory = $false,
            HelpMessage = "Specify the PSDesktop module name(s)"
        )]
        [string[]]
        $Modules,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify the PSCore module name(s)"
        )]
        [string[]]
        $ModulesCore,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to update module if installed"
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
            if ($PSVersionTable.PSEdition -eq "Core") {
                # If true, update module with core version
                $Modules = $ModulesCore
            }

            # Check if session is elevated
            $Elevated = ([Security.Principal.WindowsPrincipal] `
                    [Security.Principal.WindowsIdentity]::GetCurrent() `
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            # If Elevated, install for all users, otherwise, current user.
            if ($Elevated) {
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
            $Modules = $Modules.Trim()

            # Check if module is installed
            Write-Host "`nPerforming Dependency Check: Required Module(s): $Modules`n"
            $ModuleList = Get-Module -ListAvailable
            
            # For each module, check it is installed, if not attempt to install
            foreach ($Module in $Modules) {
                $ModuleCheck = $ModuleList | Where-Object Name -eq $Module
                if ($ModuleCheck) {
                    Write-Verbose "Module $Module is installed"

                    # If update switch is specified, attempt to update
                    if ($Update) {
                        if (!$Elevated) {
                            if ($ModuleCheck.path -like "*Program Files*") {
                                $Update = $false
                                $WarningMessage = "Skipping module update, rerun as an administrator to update this module"
                                Write-Warning $WarningMessage
                            }
                        }
                        if ($Update) {
                            write-Host "`nUpdating module $Module if update is available`n"
                            Update-Module -Name $Module
                        }
                    }
                }
                else {
                    write-Host "`nInstalling module $Module for $Scope`n"
                    Install-Module -Name $Module -AllowClobber -Force -Scope $Scope -ErrorAction Stop
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