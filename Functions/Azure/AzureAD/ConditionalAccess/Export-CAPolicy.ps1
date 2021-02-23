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
.PARAMETER TenantName
    The initial domain (onmicrosoft.com) of the tenant
.PARAMETER AccessToken
    The access token, obtained from executing Get-MSGraphAccessToken
.PARAMETER FilePath
    The file path (including file name) of where the new JSON file will be created
.PARAMETER ExcludePreviewFeatures
    Specify whether to exclude features in preview, a production API version will then be used instead
.PARAMETER ExcludeExportCleanup
    Specify whether to exclude the cleanup operations of the policies to be exported
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
                TenantDomain = ""
                FilePath = ""
    }
    Export-CAPolicy @Parameters
    $AccessToken | Export-CAPolicy
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
            HelpMessage = "The file path where the new JSON file will be created"
        )]
        [string]$FilePath,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether to exclude features in preview, a production API version will then be used instead"
        )]
        [switch]$ExcludePreviewFeatures,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "Specify whether to exclude the cleanup operations of the policies to be exported"
        )]
        [switch]$ExcludeExportCleanup
    )
    Begin {
        try {
            # Function definitions
            $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
            $Functions = @(
                "$FunctionLocation\GraphAPI\Get-MSGraphAccessToken.ps1",
                "$FunctionLocation\GraphAPI\Invoke-MSGraphQuery.ps1",
                "$FunctionLocation\Azure\AzureAD\ConditionalAccess\Get-CAPolicy.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

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
                if ($ExcludePreviewFeatures) {
                    $ConditionalAccessPolicies = Get-CAPolicy -AccessToken $AccessToken -ExcludeTagEvaluation -ExcludePreviewFeatures
                }
                else {
                    $ConditionalAccessPolicies = Get-CAPolicy -AccessToken $AccessToken -ExcludeTagEvaluation
                }
                
                # If a response is returned that was not an error
                if ($ConditionalAccessPolicies) {
                    # Sort and export query
                    $ConditionalAccessPolicies | Sort-Object createdDateTime | ConvertTo-Json -Depth 10 | Out-File -Force:$true -FilePath "$FilePath\$TenantDomain.json"

                    # Cleanup file
                    $CleanUp = Get-Content "$FilePath\$TenantDomain.json" | Select-String -Pattern '"id":', '"createdDateTime":', '"modifiedDateTime":' -notmatch

                    $CleanUp | Out-File -Force:$true -FilePath "$FilePath\$TenantDomain.json"
                }
                else {
                    $ErrorMessage = "Microsoft Graph did not return a valid response"
                    Write-Error $ErrorMessage
                }
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