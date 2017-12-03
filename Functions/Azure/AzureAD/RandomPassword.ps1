$Characters = ([char[]]([char]33..[char]95)) + ([char[]]([char]97..[char]126))
$Randomise = $Characters | Sort-Object {Get-Random}
$Password = $Randomise[1..8] -join ""