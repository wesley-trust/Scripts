<#
.Synopsis
    Run a Microsoft Graph query
.Description
    This function will run a query against Microsoft Graph and return the result
.PARAMETER Method
    The HTTP method for the Graph call, like GET, POST, PUT, PATCH, DELETE. Default is GET
.PARAMETER Uri
    The Uniform Resource Identifier for the Microsoft Graph API call, for example: "v1.0/users/"
.PARAMETER Body
    The request body of the Microsoft Graph API call. Used with methods such as POST, PUT and PATCH. Not required for GET.
.PARAMETER AccessToken
    The access token, obtained from executing Get-MSGraphAccessToken
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Reference: https://danielchronlund.com/2018/11/19/fetch-data-from-microsoft-graph-with-powershell-paging-support/
.Example
    Invoke-MSGraphQuery -AccessToken $AccessToken -Method "GET" -Uri "v1.0/users/"
    $QueryObject | Invoke-MSGraphQuery -Method "GET" -Uri "v1.0/users/"
    $AccessToken | Invoke-MSGraphQuery -Method "GET" -Uri "v1.0/users/"
#>

function Invoke-MSGraphQuery {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The HTTP method for the Microsoft Graph call. Default is GET"
        )]
        [string]$Method = "GET",
        [parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The Uniform Resource Identifier for the Microsoft Graph API call"
        )]
        [string]$Uri,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The request body of the Microsoft Graph API call"
        )]
        [string]$Body,
        [parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The access token, obtained from executing Get-MSGraphAccessToken"
        )]
        [string]$AccessToken
    )
    Begin {
        try {
            # Variables
            $ResourceUrl = "https://graph.microsoft.com"
            $ContentType = "application/json"
            $HeaderParameters = @{
                "Content-Type"  = "application\json"
                "Authorization" = "Bearer $AccessToken"
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
            if ($AccessToken) {

                # Create an empty array to store the result
                $QueryRequest = @()
                $QueryResult = @()

                # If the request is to get data, invoke without a body, otherwise append body
                if ($Method -eq "GET") {
                    $QueryRequest = Invoke-RestMethod `
                        -Headers $HeaderParameters `
                        -Uri $ResourceUrl/$Uri `
                        -UseBasicParsing `
                        -Method $Method `
                        -ContentType $ContentType
                }
                else {
                    $QueryRequest = Invoke-RestMethod `
                        -Headers $HeaderParameters `
                        -Uri $ResourceUrl/$Uri `
                        -UseBasicParsing `
                        -Method $Method `
                        -ContentType $ContentType `
                        -Body $Body
                }

                if ($QueryRequest.value) {
                    $QueryResult += $QueryRequest.value
                }
                else {
                    $QueryResult += $QueryRequest
                }

                # Invoke REST methods and fetch data until there are no pages left
                if ("$ResourceUrl/$Uri" -notlike "*`$top*") {
                    while ($QueryRequest."@odata.nextLink") {
                        $QueryRequest = Invoke-RestMethod `
                            -Headers $HeaderParameters `
                            -Uri $QueryRequest."@odata.nextLink" `
                            -UseBasicParsing `
                            -Method $Method `
                            -ContentType $ContentType

                        $QueryResult += $QueryRequest.value
                    }
                }
                $QueryResult
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