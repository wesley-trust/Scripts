<#
.Synopsis
    Export all Conditional Access policies to JSON
.Description
    This function exports the Conditional Access policies to JSON using the Microsoft Graph API.
    The following Microsoft Graph API permissions are required for the service principal used for authentication:
        Policy.ReadWrite.ConditionalAccess
        Policy.Read.All
        Directory.Read.All
        Agreement.Read.All
        Application.Read.All
.PARAMETER ClientID
    Client ID for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER ClientSecret
    Client secret for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER FilePath
    The file path where the new JSON file will be created. When not specified, this defaults to the current directory.
.INPUTS
    None
.OUTPUTS
    JSON file with all Conditional Access policies
.NOTES
    Reference: https://danielchronlund.com/2018/11/19/fetch-data-from-microsoft-graph-with-powershell-paging-support/
.Example
    $Parameters = @{
                ClientID = ""
                ClientSecret = ""
                FilePath = ""
    }
    Export-CAPolicy @Parameters
#>

function Export-CAPolicy {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Client ID for the Azure AD service principal with Conditional Access Graph permissions"
        )]
        [string]$ClientID,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Client secret for the Azure AD service principal with Conditional Access Graph permissions"
        )]
        [string]$ClientSecret,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The initial domain (onmicrosoft.com) of the tenant"
        )]
        [string]$TenantDomain,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The access token, obtained from executing Get-MSGraphAccessToken"
        )]
        [string]$AccessToken,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The file path where the new JSON file will be created. When not specified, this defaults to the current directory."
        )]
        [string]$FilePath
    )
    Begin {
        try {
            # Variables
            $ResourceUrl = "https://graph.microsoft.com"
            $Method = "Get"
            $Uri = "beta/identity/conditionalAccess/policies"
            
            # Force TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {
            # If there is no access token, obtain one
            if (!$AccessToken) {
                $AccessToken = Get-MSGraphAccessToken `
                    -ClientID $ClientID `
                    -ClientSecret $ClientSecret `
                    -TenantDomain $TenantDomain
            }
            if ($AccessToken) {
                $Query = $AccessToken | Invoke-MSGraphQuery 
                -Method $Method
                -Uri $ResourceUrl/$Uri
                
                # Sort and export query
                $Query | Sort-Object createdDateTime | ConvertTo-Json -Depth 10 | Out-File -Force:$true -FilePath $FilePath

                # Cleanup file
                $CleanUp = Get-Content $FilePath | Select-String -Pattern '"id":', '"createdDateTime":', '"modifiedDateTime":' -notmatch
            
                $CleanUp | Out-File -Force:$true -FilePath $FilePath
            }
            else {
                $ErrorMessage = "No access token specified, obtain an access token object from Get-MSGraphAccessToken"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    End {
        
    }
}