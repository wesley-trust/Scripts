<#
#Script name: New-RandomString
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 1
#References: 

.Synopsis
    Function that creates a random string (potential password), with default length of 12 characters and a max of 92.
.Description

.Example
    New-RandomPassword -CharacterLength $Length
.Example
    
#>

function New-RandomString() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the character length (maximum 92)"
        )]
        [ValidateRange(1,92)]
        [int]
        $CharacterLength = 12,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to use lower case characters only"
        )]
        [bool]
        $Simplified = $false
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
            # Character set variables
            $LowerCase = ([char[]](97..122))
            $UpperCase = ([char[]](65..90))
            $Numbers = ([char[]](48..57))
            $Special = ([char[]](33..47))
            
            # If simplified is specified
            if ($Simplified){
                $CharacterSet = $LowerCase+$UpperCase
            }
            else {
                $CharacterSet = $LowerCase+$UpperCase+$Numbers+$Special
            }

            # Randomise set
            $RandomisedSet = $CharacterSet | Sort-Object {Get-Random}
            
            # Specify length
            $Object = $RandomisedSet[1..$CharacterLength]
            
            # Join objects to form string
            $String = $Object -join ""
            
            # Return string
            return $string
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}