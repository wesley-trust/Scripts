# Variables
$cspdomain = ""
$appid = ""
$PCcreds = Get-Credential -Message "Please provide your Partner Center Admin Credentials."
$EmailCreds = Get-Credential -Message "Please provide your Office 365 Credentials."
$From = ""
$To = ""
$SmtpServer = "smtp.office365.com"
$Subject = "Partner Center Licensing: "

# Build email parameters
$EmailParameters = @{
    from = $From
    To = $To
    SmtpServer = $SmtpServer
    Port = 587
    UseSsl = $true
    BodyAsHtml = $true
    Credential = $EmailCreds
}

# Authentication
Add-PCAuthentication -cspAppID $appid -credential $PCcreds -cspdomain $cspdomain

# Get customers
$Customers = Get-PCCustomer -all

# For each customer
foreach ($Customer in $Customers) {
    $CustomerReport = Get-PCCustomerLicensesDeployment -tenantid $Customer.id 2> Out-Null
    
    # If there is a customer licence report
    if ($CustomerReport){
        
        # Return specific headings
        $CustomerReport = $CustomerReport | Select-Object productName,licensesDeployed,deploymentPercent,licensesSold
        
        # Create customer specific variable
        $CustomerSubject = $Subject+$Customer.companyprofile.companyName
        
        # Create Body HTML string
        $CustomerBody = $CustomerReport | ConvertTo-Html | Out-String
        
        # Send message
        Send-Mailmessage `
            -Subject $CustomerSubject `
            -Body $CustomerBody `
            @EmailParameters
    }
}