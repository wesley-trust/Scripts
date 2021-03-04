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
            HelpMessage = "Specify whether to skip module update"
        )]
        [switch]
        $SkipUpdate
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
                    ModuleName = $Module
                }
                if ($ModuleCheck) {
                    $ObjectProperties += @{
                        Installed = $true
                        Path      = $ModuleCheck.path
                    }
                }
                else {
                    $ObjectProperties += @{
                        Installed = $false
                        Path      = $null
                    }
                }
                New-Object -TypeName psobject -Property $ObjectProperties
            }

            # Output dependency status to host
            $ModuleStatus | Format-Table ModuleName, Installed -Autosize | Out-Host

            # Set PSGallery as trusted source if not set
            $PSRepository = Get-PSRepository -Name "PSGallery"
            if ($PSRepository.InstallationPolicy -ne "Trusted"){
                Write-Verbose "Setting PSGallery as trusted installation source"
                Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            }

            # If module is installed, update if true and where elevation allows
            $ModuleInstalled = $ModuleStatus | Where-Object Installed -eq $true
            if (!$SkipUpdate) {
                foreach ($Module in $ModuleInstalled) {
                    if (!$Elevated) {
                        if ($Module.path -like "*Program Files*") {
                            $SkipUpdate = $true
                            $WarningMessage = "Skipping module update, rerun as an administrator to update this module"
                            Write-Warning $WarningMessage
                        }
                    }
                    if (!$SkipUpdate) {
                        Write-Host "`nUpdating Module $($Module.ModuleName) (if available)`n"
                        Write-Verbose "Restarting PowerShell may be required"
                        Update-Module -Name $Module.ModuleName
                    }
                }
            }

            # If module is not installed, attempt to install
            $ModuleNotInstalled = $ModuleStatus | Where-Object Installed -eq $false
            foreach ($Module in $ModuleNotInstalled) {
                write-Host "`nInstalling module $($Module.ModuleName) for $Scope`n"
                Install-Module -Name $Module.ModuleName -AllowClobber -Force -Scope $Scope -ErrorAction Stop
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