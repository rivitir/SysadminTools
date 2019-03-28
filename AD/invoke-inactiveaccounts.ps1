<#

    Script to disable accounts that have not been used in over X of days, and email a report.
    Written by James Stull aka Rivitir

    Version 1.0 - Find and Disable accounts, then send an email log if any accounts are disabled.

#>


# Lets setup our variables

# Email Variables Edit the below for your use.
$smtpsettings = @{
    smtpserver = "smtpservernamehere.fqdn.com"
    from = "fromaddress@emaildomain.com"
    to = "UserOrDistroGroup@emaildomain.com"
    subject = "Inactive User Accounts"
}


# Setup logging to local run path. This will log to the local path you run the script from.
$logpath = (get-item -Path ".\").FullName
$logfile = $logpath + "\inactiveaccounts.log"
write-host = $logfile

# Total number of days to check for inactive accounts.
# ie: 180 means accounts that have not been used for over 6 months
$age = 30
# These are the OU's we are going to be running this job against. Note this is recursive.
# Use this line if you only need to run this against a single OU
# $UserOUs = "OU=Users,DC=EXAMPLELDAP,DC=COM"
# Use this line if you need to run this against multiple OU's. Note this is recursive.
$UserOUs = @("OU=Users1,DC=EXAMPLELDAP,DC=COM","OU=Users2,DC=EXAMPLELDAP,DC=COM")
# Need an emty array to build off of.
$disabledusers = @()

# Activate Logging
"------------------------------------------------" | out-file $logfile -Append
" " | out-file $logfile -Append
"Starting Process..." | out-file $logfile -Append
get-date  | out-file $logfile -Append

# Start the report
"Generating report for all accounts older than $age days..." | out-file $logfile -Append
foreach ($OU in $UserOUs) {
    $disabledusers += Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase $OU -Properties Name,SamAccountName,LastLogonDate | `
    Where-Object {($_.LastLogonDate -lt (Get-Date).AddDays(-$age)) -and ($_.LastLogonDate -ne $NULL)} | `
    Select-Object Name,SamAccountName,LastLogonDate
}

# Need to see if $disabledusers is null, if so then we need to log this and send a message.
if ($disabledusers.count -le 0){
    "No inactive accounts older than $age days found." | Out-File $logfile -Append
    $messageBody = @"
    No inactive accounts older than $age days found.
    This message was Sent from $env:COMPUTERNAME
"@
    
    send-mailmessage @smtpsettings -body $messageBody
} else {
    
    $useraccountnames = $disabledusers.SamAccountName
    $usercount = $disabledusers.SamAccountName.Count
    "A total of $usercount accounts were found." | out-file $logfile -Append

    $date = get-date -uformat "%Y/%m/%d"

    foreach ($useraccount in $useraccountnames) {
    set-aduser $useraccount -Enabled $False -Description "Account disabled on $date due to $age days inactivity by Policy"
    }

    "The following Accounts have been disabled." | Out-File $logfile -Append
    $disabledusers | out-file $logfile -Append

    $htmlhead = "<html>
    <style>
    BODY{font-family: Calibri; font-size: 11pt;}
    				H1{font-size: 22px; font-family: 'Segoe UI Light','Segoe UI','Lucida Grande',Verdana,Arial,Helvetica,sans-serif;}
    				H2{font-size: 18px; font-family: 'Segoe UI Light','Segoe UI','Lucida Grande',Verdana,Arial,Helvetica,sans-serif;}
                    H3{font-size: 16px; font-family: 'Segoe UI Light','Segoe UI','Lucida Grande',Verdana,Arial,Helvetica,sans-serif;}
    				TABLE{border: 1px solid black; border-collapse: collapse; font-family: Calibri; font-size: 11pt;}
    				TH{border: 1px solid #969595; background: #dddddd; padding: 5px; color: #000000;}
    				TD{border: 1px solid #969595; padding: 5px; }
    				td.pass{background: #B7EB83;}
    				td.warn{background: #FFF275;}
    				td.fail{background: #FF2626; color: #ffffff;}
    				td.info{background: #85D4FF;}
    				</style>
    				<body>
                    <p>A total of $usercount accounts were found.<br>
                    The following Accounts have been disabled.<br>
                    This message was Sent from $env:COMPUTERNAME</p>"

    $htmltail = "</body></html>"

    $html = $disabledusers | ConvertTo-Html -Fragment
    
    $body = $htmlhead + $html + $htmltail

    send-mailmessage @smtpsettings -body $body -BodyAsHtml
}

"Job finished." | out-file $logfile -Append
