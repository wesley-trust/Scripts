<#
.Synopsis
    Perform display name tagging on the query responses from the Microsoft Graph
.Description
    This function evaluates whether tags are present in the display name, and if so, adds the tag values to the object returned
.PARAMETER Tags
    Client ID for the Azure AD service principal with Conditional Access Graph permissions
.PARAMETER QueryResponse
    Client secret for the Azure AD service principal with Conditional Access Graph permissions
.INPUTS
    None
.OUTPUTS
    None
.NOTES

.Example
    Invoke-WTPropertyTagging -Tags $Tags -QueryResponse $QueryResponse
    $QueryResponse | Invoke-WTPropertyTagging -Tags $Tags
#>

function Invoke-WTPropertyTagging {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The tags to be evaluated"
        )]
        [string[]]$Tags,
        [parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true,
            HelpMessage = "The property to tag within the input object"
        )]
        [string]$PropertyToTag,
        [parameter(
            Mandatory = $true,
            ValueFromPipeLineByPropertyName = $true,
            ValueFromPipeLine = $true,
            HelpMessage = "The input object"
        )]
        [psobject]$QueryResponse
    )
    Begin {
        try {
            
            # Variables
            $MajorDelimiter = ";"
            $MinorDelimiter = "-"
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {

            # Get Query properties
            $QueryProperties = ($QueryResponse | Get-Member -MemberType NoteProperty).name 
            
            foreach ($Query in $QueryResponse) {
                
                # Split out Query information by defined delimeter(s) and tag(s)
                $QueryPropertySplit = ($Query.$PropertyToTag.split($MajorDelimiter)).Split($MinorDelimiter)

                $TaggedQueryResponse = [ordered]@{}
                foreach ($Tag in $Tags) {

                    # If the tag exists in the display name, 
                    if ($QueryPropertySplit -contains $Tag) {

                        # Get the object index, increment by one to obtain the tag's value index
                        $TagIndex = $QueryPropertySplit.IndexOf($Tag)
                        $TagValueIndex = $TagIndex + 1
                        $TagValue = $QueryPropertySplit[$TagValueIndex]
                        
                        # Add tag to hashtable
                        $TaggedQueryResponse.Add($Tag, $TagValue)
                    }
                    else {
                        $TaggedQueryResponse.Add($Tag, $null)
                    }
                }
                            
                # Append all properties and return object
                foreach ($Property in $QueryProperties) {
                    $TaggedQueryResponse.Add("$Property", $Query.$Property)
                }

                [pscustomobject]$TaggedQueryResponse
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
