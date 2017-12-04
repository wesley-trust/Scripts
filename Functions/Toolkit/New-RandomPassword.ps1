<#
#Script name: New-RandomPassword
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 1
#References: 

.Synopsis
    Function that creates a random password, with default length of 12 characters and a max of 92.
.Description

.Example
    New-RandomPassword -CharacterLength $Length
.Example
    
#>

function New-RandomPassword() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the character length (maximum 92)"
        )]
        [ValidateRange(1,92)]
        [int]
        $CharacterLength = 12
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
            # Specify character set
            $CharacterSet = ([char[]]([char]33..[char]95)) + ([char[]]([char]97..[char]126))
            
            # Randomise
            $RandomisedSet = $CharacterSet | Sort-Object {Get-Random}
            
            # Specify length
            $Password = $RandomisedSet[1..$CharacterLength]
            
            # Join objects to form password string
            $Password = $Password -join ""
            
            # Return password
            return $Password
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}