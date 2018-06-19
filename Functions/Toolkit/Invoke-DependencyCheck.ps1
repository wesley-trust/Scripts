<#
#Script name: Invoke-DependencyCheck
#Creator: Wesley Trust
#Date: 2017-12-04
#Revision: 3
#References: 

.Synopsis
    Function that checks if a required module is installed, and installs if nessessary.
.Description

.Example
    Invoke-DependencyCheck -Modules "AzureAD"
.Example
    
#>

function Invoke-DependencyCheck() {
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
            Write-Host "`nPerforming Dependency Check"
            Write-Host "`nRequired Module(s): $Modules"
            $ModuleList = Get-Module -ListAvailable
            
            # For each module, check it is installed, if not attempt to install
            $ModuleStatus = foreach ($Module in $Modules) {
                $ModuleCheck = $ModuleList | Where-Object Name -eq $Module
                $ObjectProperties = @{
                    Module = $Module
                }
                if ($ModuleCheck) {
                    $ObjectProperties += @{
                        Installed = $true
                        Path = $ModuleCheck.path
                    }
                }
                else {
                    $ObjectProperties += @{
                        Installed = $false
                    }
                }
                New-Object -TypeName psobject -Property $ObjectProperties
            }
            
            # Output dependency status to host
            $ModuleStatus | Format-Table Module,Installed -Autosize | Out-Host
           
            # If module is installed, update if true and where elevation allows
            $ModuleInstalled = $ModuleStatus | Where-Object Installed -eq $true
            if ($Update) {
                foreach ($Module in $ModuleInstalled){
                    if (!$Elevated) {
                        if ($Module.path -like "*Program Files*") {
                            $Update = $false
                            $WarningMessage = "Skipping module update, rerun as an administrator to update this module"
                            Write-Warning $WarningMessage
                        }
                    }
                    if ($Update) {
                        write-Host "`nUpdating module $Module`n"
                        Update-Module -Name $Module
                    }
                }
            }

            # If module is not installed, attempt to install
            $ModuleNotInstalled = $ModuleStatus | Where-Object Installed -eq $false
            foreach ($Module in $ModuleNotInstalled){
                write-Host "`nInstalling module $Module for $Scope`n"
                Install-Module -Name $Module -AllowClobber -Force -Scope $Scope -ErrorAction Stop
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