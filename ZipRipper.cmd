@ECHO OFF
CALL :SINGLEINSTANCE
IF NOT "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
CALL :CENTERWINDOW
ECHO FOR USE WITH x64 SYSTEMS ONLY
ECHO/
PAUSE
GOTO :EOF
) ELSE (
CALL :CENTERWINDOW
ECHO UNABLE TO LAUNCH IN x86 MODE
ECHO/
PAUSE
GOTO :EOF
)
)
IF NOT "%~2"=="" (
CALL :CENTERWINDOW
ECHO Multiple files are not supported. Double-click the script and use the GUI to select a file...
ECHO/
PAUSE
GOTO :EOF
)
SET OFFLINE=1
IF NOT EXIST "%~dp0zr-offline.txt" (
SET OFFLINE=0
CALL :CHECKCONNECTION
)
>nul 2>&1 REG ADD HKCU\Software\classes\.ZipRipper\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=1\"&CALL \"%%2\" %%3"
IF /I NOT "%~dp0" == "%ProgramData%\" (
CALL :CLEANUP STARTUP
ECHO|(SET /p="%~dp0")>"%ProgramData%\launcher.ZipRipper"
>nul 2>&1 COPY /Y "%~f0" "%ProgramData%"
IF EXIST "%~dp0zr-offline.txt" >nul 2>&1 COPY /Y "%~dp0zr-offline.txt" "%ProgramData%"
>nul 2>&1 FLTMC && (TITLE Re-Launching...&START "" /min "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0") || IF NOT "%f0%"=="1" (TITLE Re-Launching...&START "" /min /high "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0"&EXIT /b)
EXIT /b
)
SET "NATIVE=ZIP,RAR"
SET "PERL=7z,PDF"
SET GPU=0
SET ALLOWSTART=0
CALL :CHECKWIN
CALL :CHECKGPU
IF EXIST "%ProgramData%\JtR" >nul 2>&1 RD "%ProgramData%\JtR" /S /Q
>nul 2>&1 ATTRIB -h "%ProgramData%\BIT*.tmp"
IF EXIST "%ProgramData%\BIT*.tmp" >nul 2>&1 DEL "%ProgramData%\BIT*.tmp" /F /Q
CALL :CENTERWINDOW
IF "%OFFLINE%"=="1" CALL :OFFLINEMODE
IF "%~1"=="" (
ECHO USE THE GUI TO PROCEED
SETLOCAL ENABLEDELAYEDEXPANSION

:MAIN
CALL :MAINMENU ACTION
IF "!ACTION!"=="Offline" (
ENDLOCAL
CALL :BUILD RELAUNCH
SETLOCAL ENABLEDELAYEDEXPANSION
SET /p OFOLDER=<"%ProgramData%\launcher.ZipRipper"
IF "!RELAUNCH!"=="1" (
TITLE Re-Launching...
START "" /min "%ProgramData%\launcher.ZipRipper" "!OFOLDER!%~nx0"
ENDLOCAL
EXIT /b
) ELSE (
ENDLOCAL
CALL :CLEANUP
)
)
IF NOT "!ACTION!"=="Start" (
ENDLOCAL
CALL :CLEANUP
)
CALL :GETFILE FILENAME
IF NOT EXIST !FILENAME! GOTO :MAIN
TITLE Re-Launching...
START "" "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0" "!FILENAME:"=""!"
ENDLOCAL
EXIT /b
)
FOR %%# IN (%NATIVE%) DO IF /I "%~x1"==".%%#" (
SET ALLOWSTART=1
SET ISPERL=0
)
FOR %%# IN (%PERL%) DO IF /I "%~x1"==".%%#" (
SET ALLOWSTART=1
SET ISPERL=1
)
IF NOT "%ALLOWSTART%"=="1" CALL :CLEANUP
>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F 
>nul 2>&1 DEL "%ProgramData%\launcher.ZipRipper" /F /Q
SET "FILETYPE=%~x1"
SET "TitleName=^[ZIP-Ripper^]  -  ^[CPU Mode^]  -  ^[OpenCL DISABLED^]  -  Offline Mode"
IF %GPU% GEQ 1 SET TitleName=%TitleName:^[CPU Mode^]  -  ^[OpenCL DISABLED^]=^[CPU/GPU Mode^]  -  ^[OpenCL ENABLED^]%
IF "%OFFLINE%"=="0" SET TitleName=%TitleName:Offline=Online%
TITLE %TitleName%
IF "%OFFLINE%"=="0" CALL :ONLINEMODE
CALL :GETJTRREADY
ECHO Done
ECHO/
PUSHD "%ProgramData%\JtR\run"
REN john.conf john.defaultconf
POWERSHELL -nop -c "$^=gc john.defaultconf|%%{$_.Replace('SingleMaxBufferAvailMem = N','SingleMaxBufferAvailMem = Y').Replace('MaxKPCWarnings = 10','MaxKPCWarnings = 0')}|sc john.conf">nul 2>&1
SET "FLAG="
IF %~z1 GEQ 200000000 (
<NUL set /p=Creating password hash - This can take a few minutes on large files...
) ELSE (
<NUL set /p=Creating password hash...
)
SET RESUME=0
CALL :GETMD5 %1 MD5
SETLOCAL ENABLEDELAYEDEXPANSION
IF EXIST "%AppData%\ZR-InProgress\!MD5!" (
ENDLOCAL
CALL :RESUMEDECIDE ISRESUME
SETLOCAL ENABLEDELAYEDEXPANSION
IF "!ISRESUME!"=="1" (
>nul 2>&1 COPY /Y "%AppData%\ZR-InProgress\!MD5!\*.*" "%ProgramData%\JtR\run\"
ENDLOCAL
CALL :CHECKRESUMENAME %1
SET RESUME=1
GOTO :STARTJTR
) ELSE (
>nul 2>&1 RD "%AppData%\ZR-InProgress\!MD5!" /S /Q
ENDLOCAL
)
)
ENDLOCAL
SET ZIP2=0
SET PROTECTED=1
SET /A HSIZE=0
CALL :HASH%FILETYPE% %1
ECHO Done
ECHO/
SETLOCAL ENABLEDELAYEDEXPANSION
IF "!PROTECTED!"=="0" CALL :NOTPROTECTED %1&EXIT /b
ENDLOCAL

:STARTJTR
CLS
ECHO Running JohnTheRipper...
ECHO/
IF "%RESUME%"=="1" (
ECHO Resuming Session...
ECHO/
john --restore
) ELSE (
SETLOCAL ENABLEDELAYEDEXPANSION
john "%ProgramData%\JtR\run\pwhash" --wordlist="%ProgramData%\JtR\run\password.lst" --rules=single,all !FLAG!
ENDLOCAL
)
CALL :GETSIZE "%ProgramData%\JtR\run\john.pot" POTSIZE
SETLOCAL ENABLEDELAYEDEXPANSION
IF !POTSIZE! GEQ 1 (
ENDLOCAL
SET FOUND=1
CALL :SAVEFILE %1
SETLOCAL ENABLEDELAYEDEXPANSION
IF EXIST "%AppData%\ZR-InProgress\!MD5!" >nul 2>&1 RD "%AppData%\ZR-InProgress\!MD5!" /S /Q
ENDLOCAL
ECHO/
ECHO Passwords saved to: "%UserProfile%\Desktop\ZipRipper-Passwords.txt"
) ELSE (
ENDLOCAL
SET FOUND=0
ECHO/
CALL :SETRESUME %1
)
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT "!FOUND!"=="0" (
CALL :GETSIZE "%UserProfile%\Desktop\ZipRipper-Passwords.txt" PWSIZE
IF !PWSIZE! LEQ 1600 (
ENDLOCAL
CALL :DISPLAYINFOA
) ELSE (
ENDLOCAL
CALL :DISPLAYINFOB
)
)
ECHO/
PAUSE
POPD
CALL :CLEANUP
GOTO :EOF

:GETMD5
SET "MD5FILE=%~1"
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=Resolve-Path '%MD5FILE:'=''%';$md5=new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider;$f=[System.IO.File]::Open($^,[System.IO.Filemode]::Open,[System.IO.FileAccess]::Read);try{[System.BitConverter]::ToString($md5.ComputeHash($f)).Replace('-','').ToLower()}finally{$f.Dispose()}"`) DO SET %2=%%#
EXIT /b

:RESUMEDECIDE
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup('Click OK to resume, or Cancel to remove the saved job and start over',0,'There is a job in progress for this file!',0x1)"`) DO SET %1=%%#
EXIT /b

:SETRESUME
IF NOT EXIST "%ProgramData%\JtR\run\john.rec" (
ECHO Resume is UNAVAILABLE for this file ;^(
) ELSE (
ECHO Resume is available for the next session...
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT EXIST "%AppData%\ZR-InProgress\!MD5!" MD "%AppData%\ZR-InProgress\!MD5!"
>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\pwhash" "%AppData%\ZR-InProgress\!MD5!"
>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.pot" "%AppData%\ZR-InProgress\!MD5!"
>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.rec" "%AppData%\ZR-InProgress\!MD5!"
>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.log" "%AppData%\ZR-InProgress\!MD5!"
ENDLOCAL
)
EXIT /b

:NOTPROTECTED
CLS
ECHO "%~1" is not password protected..
ECHO/
PAUSE
EXIT /b 

:ONLINEMODE
<NUL set /p=Please Wait...
SET /A P=3&SET /A PT=11
IF "%ISPERL%"=="1" SET "PERL2=$info.Text=' Downloading Portable Perl';Update-Gui;downloadFile 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip' '%ProgramData%\perlportable.zip';"&SET /A P=4&SET /A PT=8
POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^"" Initializing..."^"" Height="^""75"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""3"^"" Text="^"" Initializing..."^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""28"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress"^"" Foreground="^""#FF0000"^""/><TextBlock Name="^""Info2"^"" Canvas.Top="^""38"^"" Text="^"" Getting Resources (Online Mode)"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""63"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress2"^"" Foreground="^""#FF0000"^""/></Canvas><Window.TaskbarItemInfo><TaskbarItemInfo/></Window.TaskbarItemInfo></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage;$bitmap='%LOGO:'=''%';$form.Icon=$bitmap;$form.TaskbarItemInfo.Overlay=$bitmap;$form.TaskbarItemInfo.Description=$form.Title;$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$progressBar=$form.FindName("^""Progress"^"");$progressTotal=$form.FindName("^""Progress2"^"");$info=$form.FindName("^""Info"^"");$info2=$form.FindName("^""Info2"^"");function Update-Gui(){$form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})};function GetResources(){$info.Text=' Initializing...';$progressTotal.Value=%PT%;Update-Gui;$info.Text=' Downloading 7zr Standalone';Update-Gui;downloadFile 'https://www.7-zip.org/a/7zr.exe' '%ProgramData%\7zr.exe';$info.Text=' Downloading 7za Console';Update-Gui;downloadFile 'https://www.7-zip.org/a/7z2300-extra.7z' '%ProgramData%\7zExtra.7z';$info.Text=' Downloading JohnTheRipper';Update-Gui;downloadFile 'https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z' '%ProgramData%\winX64_1_JtR.7z';%PERL2%$progressTotal.Value=100;$info.Text="^"" Ready..."^"";Update-Gui};function DownloadFile($url,$targetFile){$uri=New-Object "^""System.Uri"^"" "^""$url"^"";$request=[System.Net.HttpWebRequest]::Create($uri);$request.set_Timeout(15000);$response=$request.GetResponse();$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024);$responseStream=$response.GetResponseStream();$targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create;$buffer=new-object byte[] 10KB;$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$count;while ($count -gt 0){$targetStream.Write($buffer, 0, $count);$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$downloadedBytes + $count;$roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength) * 100);$progressBar.Value=$roundedPercent;if($totalP -ge %P%){$progressTotal.Value++;$totalP=0};if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;$totalP++;Update-Gui}};$targetStream.Flush();$targetStream.Close();$targetStream.Dispose();$responseStream.Dispose()};$form.Add_ContentRendered({GetResources;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)">nul
ECHO Ready
ECHO/
EXIT /b

:OFFLINEMODE
SET NEEDED=7zr.exe,7zExtra.7z,winX64_1_JtR.7z,perlportable.zip,zipripper.png
SET EXTRACT=0
<NUL set /p=Offline mode enabled
FOR %%# IN (%NEEDED%) DO (
IF /I NOT EXIST "%~dp0%%#" SET EXTRACT=1
)
IF NOT "%EXTRACT%"=="1" (
<NUL set /p=, checking resources...
) ELSE (
<NUL set /p=, preparing resources...
PUSHD "%~dp0"
POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^"" Initializing..."^"" Height="^""37"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""10"^"" Canvas.Left="^""23"^"" Text="^"" Initializing... (Offline Mode)"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/></Canvas></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});function ExtractFile(){&expand -R zr-offline.txt -F:* .};$form.Add_ContentRendered({ExtractFile;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)"
POPD
)
ECHO Done
ECHO/
EXIT /b

:GETJTRREADY
IF "%ISPERL%"=="1" (
<NUL set /p=Extracting required dependencies, this will take a moment...
) ELSE (
<NUL set /p=Extracting required dependencies...
)
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\winX64_1_JtR.7z" -o"%ProgramData%\"
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\7zExtra.7z" -o"%ProgramData%\JtR\"
IF "%ISPERL%"=="1" "%ProgramData%\JtR\7za.exe" x -y "%ProgramData%\perlportable.zip" -o"%ProgramData%\JtR\run">nul
IF EXIST "%ProgramData%\perlportable.zip" >nul 2>&1 DEL "%ProgramData%\perlportable.zip" /F /Q
IF EXIST "%ProgramData%\zr-offline.txt" >nul 2>&1 DEL "%ProgramData%\zr-offline.txt" /F /Q
>nul 2>&1 DEL "%ProgramData%\winX64_1_JtR.7z" /F /Q
>nul 2>&1 DEL "%ProgramData%\7zr.exe" /F /Q
>nul 2>&1 DEL "%ProgramData%\7zExtra.7z" /F /Q
IF %GPU% EQU 1 >nul 2>&1 COPY /Y "%WinDir%\System32\OpenCL.dll" "%ProgramData%\JtR\run\cygOpenCL-1.dll"
EXIT /b

:CHECKWIN
FOR /F "usebackq skip=2 tokens=3,4" %%# IN (`REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul`) DO (
IF "%%# %%$"=="Windows 7" (
ECHO/
ECHO Windows 7 detected.
ECHO/
ECHO SYSTEM NOT SUPPORTED
ECHO/
PAUSE
GOTO :EOF
)
)
EXIT /b

:CHECKGPU
FOR /F "usebackq skip=1 tokens=2,3" %%# IN (`WMIC path Win32_VideoController get Name ^| findstr "."`) DO (
IF /I "%%#"=="GeForce" SET GPU=1
IF /I "%%#"=="Quadro" SET GPU=1
IF /I "%%# %%$"=="Radeon RX" SET GPU=2
IF /I "%%# %%$"=="Radeon Pro" SET GPU=2
IF NOT EXIST "%WinDir%\System32\OpenCL.dll" SET GPU=0
)
EXIT /b

:CHECKRESUMENAME
FOR /F "usebackq tokens=1 delims=:/" %%# IN (pwhash) DO (
IF NOT "%~nx1"=="%%#" (
SET ALT=1
SET "OLDNAME=%%#"
) ELSE (
SET ALT=0
)
)
SET "NEWNAME=%~nx1"
IF "%ALT%"=="1" POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup("^""This file has been renamed since the initial session. The filename will be updated in the saved session data.`n`nInitial file name: %OLDNAME%`n`nCurrent file name: %~nx1`n`nIt is recommended that you do not change the file name after the initial session to avoid potential issues, but it is not a requirement, and the session is able to resume anyway..."^"",0,'WARNING: File name change detected!',0x0);$update=[System.IO.File]::ReadAllText('%ProgramData%\JtR\run\pwhash').Replace('%OLDNAME:'=''%','%NEWNAME:'=''%');[System.IO.File]::WriteAllText('%ProgramData%\JtR\run\pwhash', $update)">nul
EXIT /b

:HASH.ZIP
zip2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
FOR /F %%# IN ("%ProgramData%\JtR\run\pwhash") DO SET /A HSIZE=%%~z#
IF %HSIZE% EQU 0 SET PROTECTED=0
IF %GPU% GEQ 1 FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (
IF "%%#"=="zip2" (
SET "FLAG=--format=ZIP-opencl"
SET ZIP2=1
) ELSE (
IF %GPU% GEQ 1 SET TitleName=%TitleName:[CPU/GPU Mode]  -  [OpenCL ENABLED]=^[CPU Mode^]  -  ^[OpenCL UNSUPPORTED Filetype^]%
TITLE %TitleName%
)
)
EXIT /b

:HASH.RAR
rar2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>"%ProgramData%\JtR\run\statusout"
FOR /F "usebackq tokens=*" %%# IN (`TYPE "%ProgramData%\JtR\run\statusout" ^| findstr /I "Did not find"`) DO SET PROTECTED=0
IF %GPU% GEQ 1 FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (
IF /I "%%#"=="rar" SET "FLAG=--format=rar-opencl"
IF /I "%%#"=="rar3" SET "FLAG=--format=rar-opencl"
IF /I "%%#"=="rar5" SET "FLAG=--format=RAR5-opencl"
)
EXIT /b

:HASH.7z
CALL portableshell.bat 7z2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>"%ProgramData%\JtR\run\statusout"
FOR /F "usebackq tokens=*" %%# IN (`TYPE statusout ^| findstr "no AES"`) DO SET PROTECTED=0
IF %GPU% GEQ 1 SET "FLAG=--format=7z-opencl"
EXIT /b

:HASH.PDF
CALL portableshell.bat pdf2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
POWERSHELL -nop -c "$^=[regex]::Match((gc pwhash),'^(.+\/)(?i)(.*\.pdf)(.+$)');$^.Groups[2].value+$^.Groups[3].value|sc pwhash">nul 2>&1
FOR /F %%# IN ("%ProgramData%\JtR\run\pwhash") DO SET /A HSIZE=%%~z#
IF %HSIZE% LSS 8000 FOR /F "usebackq tokens=*" %%# IN (`TYPE pwhash ^| findstr "not encrypted!"`) DO SET PROTECTED=0
IF %GPU% GEQ 1 SET TitleName=%TitleName:[CPU/GPU Mode]  -  [OpenCL ENABLED]=^[CPU Mode^]  -  ^[OpenCL UNSUPPORTED Filetype^]%
TITLE %TitleName%
EXIT /b

:GETSIZE
SET /A "%2=%~z1"
IF %~z1==[] SET /A "%2=0"
EXIT /b

:SINGLE
FOR /F "usebackq tokens=2 delims=:" %%# IN (john.pot) DO ECHO|(SET /p="%%# - [%~nx1]"&ECHO/)>>"%UserProfile%\Desktop\ZipRipper-Passwords.txt"
EXIT /b

:MULTI
FOR /F "usebackq tokens=1,5 delims=*" %%# IN (pwhash) DO ECHO %%#%%$>>pwhash.x1
FOR /F "usebackq tokens=1,3 delims=$" %%# IN (pwhash.x1) DO ECHO %%#%%$>>pwhash.x2
POWERSHELL -nop -c "$^=gc john.pot|%%{$_ -Replace '^.+?\*.\*([a-z\d]{32})\*.+:(.*)$',"^""`$1:`$2"^""}|sc pwhash.x3">nul 2>&1
FOR /F "usebackq tokens=1,2 delims=:" %%# IN (pwhash.x2) DO (
FOR /F "usebackq tokens=1* delims=:" %%X IN (pwhash.x3) DO (
IF "%%$"=="%%X" ECHO|(SET /p="%%Y - [%%#]"&ECHO/)>>"%UserProfile%\Desktop\ZipRipper-Passwords.txt"
)
)
DEL /f /q pwhash.x*
EXIT /b

:RENAMEOLD
IF EXIST "%UserProfile%\Desktop\ZipRipper-Passwords.%R%.txt" (
SET /A R+=1
GOTO :RENAMEOLD
) ELSE (
REN "%UserProfile%\Desktop\ZipRipper-Passwords.txt" "ZipRipper-Passwords.%R%.txt"
)
EXIT /b

:SAVEFILE
IF EXIST "%UserProfile%\Desktop\ZipRipper-Passwords.txt" (
SET /A R=0
CALL :RENAMEOLD
)
(
ECHO ^[ZIP-Ripper^] - FOUND PASSWORDS
ECHO  %DATE% + %TIME%
ECHO ==============================
ECHO/
)>"%UserProfile%\Desktop\ZipRipper-Passwords.txt"
IF "%ZIP2%"=="1" (
CALL :MULTI
) ELSE (
CALL :SINGLE %1
)
(
ECHO/
ECHO ==============================
)>>"%UserProfile%\Desktop\ZipRipper-Passwords.txt"
EXIT /b

:DISPLAYINFOA
POWERSHELL -nop -c "$alertsound={$notifybeep=[PowerShell]::Create().AddScript({$NotifyAudio=New-Object System.Media.SoundPlayer;$NotifyAudio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$NotifyAudio.playsync()});$runspace=[RunspaceFactory]::CreateRunspace();$runspace.ApartmentState="^""STA"^"";$runspace.ThreadOptions="^""ReuseThread"^"";$runspace.Open();$notifybeep.Runspace=$runspace;$notifybeep.BeginInvoke()};&$alertsound;$Msg=@();foreach($line in Get-Content '%UserProfile%\Desktop\ZipRipper-Passwords.txt'){if($null -eq $Msg){$Msg+=$line}else{$Msg+=$line + "^""`n"^""}};$Msg+="^""Save Location:`n"^"";$Msg+="^"""^"""^""%UserProfile%\Desktop\ZipRipper-Passwords.txt"^"""^"""^"";$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup($Msg,0,'Message from ZIP-Ripper',0x0)">nul
EXIT /b

:DISPLAYINFOB
POWERSHELL -nop -c "$alertsound={$notifybeep=[PowerShell]::Create().AddScript({$NotifyAudio=New-Object System.Media.SoundPlayer;$NotifyAudio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$NotifyAudio.playsync()});$runspace=[RunspaceFactory]::CreateRunspace();$runspace.ApartmentState="^""STA"^"";$runspace.ThreadOptions="^""ReuseThread"^"";$runspace.Open();$notifybeep.Runspace=$runspace;$notifybeep.BeginInvoke()};&$alertsound;$Msg=@();$Msg+="^""[ZIP-Ripper] - FOUND PASSWORDS`n"^"";$Msg+="^"" %DATE% + %TIME%`n"^"";$Msg+="^""==============================`n"^"";$Msg+="^""`n"^"";$Msg+="^""TOO MANY TO LIST`n"^"";$Msg+="^""`n"^"";$Msg+="^""==============================`n"^"";$Msg+="^""Save Location:`n"^"";$Msg+="^"""^"""^""%UserProfile%\Desktop\ZipRipper-Passwords.txt"^"""^"""^"";$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup($Msg,0,'Message from ZIP-Ripper',0x0)">nul
EXIT /b

:CHECKCONNECTION
PING -n 1 "google.com" | FINDSTR /r /c:"[0-9] *ms">nul
IF NOT %errorlevel%==0 (
CALL :CENTERWINDOW
ECHO Internet connection not detected...
ECHO/
ECHO ^[zr-offline.txt^] must be in the same folder as ZipRipper for offline mode.
ECHO/
ECHO Click JtR on John's hat on an internet connected machine to create a local
ECHO copy of ^[zr-offline.txt^]
ECHO/
PAUSE
GOTO :EOF
)
EXIT /b

:SINGLEINSTANCE
TASKLIST /V /NH /FI "imagename eq cmd.exe"|FINDSTR /I /C:"ZIP-Ripper">nul
IF NOT %errorlevel%==1 POWERSHELL -nop -c "$alertsound={$notifybeep=[PowerShell]::Create().AddScript({$NotifyAudio=New-Object System.Media.SoundPlayer;$NotifyAudio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$NotifyAudio.playsync()});$runspace=[RunspaceFactory]::CreateRunspace();$runspace.ApartmentState="^""STA"^"";$runspace.ThreadOptions="^""ReuseThread"^"";$runspace.Open();$notifybeep.Runspace=$runspace;$notifybeep.BeginInvoke()};&$alertsound;$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup("^""ZipRipper is already running!"^"",0,'ERROR:',0x10)">nul&EXIT
TITLE ^[ZIP-Ripper^] Launching GUI...
EXIT /b

:CENTERWINDOW
>nul 2>&1 POWERSHELL -nop -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport(\"user32.dll\")]public static extern void SetProcessDPIAware();[DllImport(\"shcore.dll\")]public static extern void SetProcessDpiAwareness(int value);[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern void GetWindowRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport(\"user32.dll\")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport(\"user32.dll\")]public static extern int SetWindowPos(IntPtr hwnd, IntPtr hwndAfterZ, int x, int y, int w, int h, int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try {$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)} catch {$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7] - $moninf[5];$monheight=$moninf[8] - $moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2] - $wrect[0];$winheight=$wrect[3] - $wrect[1];$x=[int][math]::Round($moninf[5] + $monwidth / 2 - $winwidth / 2);$y=[int][math]::Round($moninf[6] + $monheight / 2 - $winheight / 2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, 0, 0, $SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
EXIT /b

:GETFILE
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName System.Windows.Forms;$^=New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory='';Title='Select a password protected ZIP, RAR, 7z or PDF...';Filter='All Supported (*.zip;*.rar;*.7z;*.pdf)|*.zip;*.rar;*.7z;*.pdf|ZIP (*.zip)|*.zip|RAR (*.rar)|*.rar|7-Zip (*.7z)|*.7z|PDF (*.pdf)|*.pdf'};$null=$^.ShowDialog();$Quoted='"^""' + $^^.Filename + '"^""';$Quoted"`) DO SET %1=%%#
EXIT /b

:MAINMENU
SET "LOGO=%ProgramData%\zipripper.png"
IF NOT EXIST "%LOGO%" (
IF "%OFFLINE%"=="0" POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^"" Initializing..."^"" Height="^""37"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""3"^"" Text="^"" Initializing..."^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""28"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress"^"" Foreground="^""#FF0000"^""/></Canvas></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$progressBar=$form.FindName("^""Progress"^"");function Update-Gui (){$form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})};function DownloadFile($url,$targetFile){$uri=New-Object "^""System.Uri"^"" "^""$url"^"";$request=[System.Net.HttpWebRequest]::Create($uri);$request.set_Timeout(15000);$response=$request.GetResponse();$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024);$responseStream=$response.GetResponseStream();$targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create;$buffer=new-object byte[] 10KB;$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$count;while ($count -gt 0){$targetStream.Write($buffer, 0, $count);$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$downloadedBytes + $count;$roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength) * 100);$progressBar.Value=$roundedPercent;if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;Update-Gui}};$targetStream.Flush();$targetStream.Close();$targetStream.Dispose();$responseStream.Dispose()};$form.Add_ContentRendered({downloadFile 'https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/zipripper.png' '%LOGO%';Sleep 1;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)"
)
FOR /F "usebackq tokens=*" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Background="^""Transparent"^"" AllowsTransparency="^""True"^"" Width="^""285"^"" Height="^""324"^""><Window.Resources><ControlTemplate x:Key="^""NoMouseOverButtonTemplate"^"" TargetType="^""Button"^""><Border Background="^""{TemplateBinding Background}"^"" BorderBrush="^""{TemplateBinding BorderBrush}"^"" BorderThickness="^""{TemplateBinding BorderThickness}"^""><ContentPresenter HorizontalAlignment="^""{TemplateBinding HorizontalContentAlignment}"^"" VerticalAlignment="^""{TemplateBinding VerticalContentAlignment}"^""/></Border><ControlTemplate.Triggers><Trigger Property="^""IsEnabled"^"" Value="^""False"^""><Setter Property="^""Background"^"" Value="^""{x:Static SystemColors.ControlLightBrush}"^""/><Setter Property="^""Foreground"^"" Value="^""{x:Static SystemColors.GrayTextBrush}"^""/></Trigger></ControlTemplate.Triggers></ControlTemplate></Window.Resources><Grid><Grid.RowDefinitions><RowDefinition Height="^""298"^""/><RowDefinition Height="^""*"^""/></Grid.RowDefinitions><Grid.Background><ImageBrush ImageSource="^""%LOGO%"^""/></Grid.Background><Grid.Triggers><EventTrigger RoutedEvent="^""Loaded"^""><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="^""Background.Opacity"^"" From="^""0"^"" To="^""1"^"" Duration="^""0:0:1"^""/></Storyboard></BeginStoryboard></EventTrigger></Grid.Triggers><Canvas Grid.Row="^""0"^""><Button x:Name="^""Offline"^"" Canvas.Left="^""141"^"" Canvas.Top="^""56"^"" Height="^""16"^"" Width="^""26"^"" ToolTip="^""Create [zr-offline.txt]"^"" Template="^""{StaticResource NoMouseOverButtonTemplate}"^""/><Button x:Name="^""Cleanup"^"" Canvas.Left="^""138"^"" Canvas.Top="^""154"^"" Height="^""20"^"" Width="^""20"^"" ToolTip="^""Clear Resume Cache"^"" Template="^""{StaticResource NoMouseOverButtonTemplate}"^""/></Canvas><Canvas Grid.Row="^""1"^""><Button x:Name="^""Start"^"" Height="^""22"^"" Width="^""65"^"" Content="^""Start"^"" ToolTip="^""Click to Begin..."^"" Template="^""{StaticResource NoMouseOverButtonTemplate}"^""><Button.Triggers><EventTrigger RoutedEvent="^""Loaded"^""><BeginStoryboard><Storyboard><DoubleAnimation From="^""40"^"" To="^""65"^"" Duration="^""0:0:1"^"" Storyboard.TargetProperty="^""(Canvas.Left)"^"" AutoReverse="^""False"^""/><DoubleAnimation Storyboard.TargetProperty="^""Opacity"^"" From="^""0"^"" To="^""1"^"" Duration="^""0:0:2"^""/></Storyboard></BeginStoryboard></EventTrigger></Button.Triggers></Button></Canvas><Canvas Grid.Row="^""1"^""><Button x:Name="^""Quit"^"" Height="^""22"^"" Width="^""65"^"" Content="^""Quit"^"" ToolTip="^""Click to Exit"^"" Template="^""{StaticResource NoMouseOverButtonTemplate}"^""><Button.Triggers><EventTrigger RoutedEvent="^""Loaded"^""><BeginStoryboard><Storyboard><DoubleAnimation From="^""40"^"" To="^""65"^"" Duration="^""0:0:1"^"" Storyboard.TargetProperty="^""(Canvas.Right)"^"" AutoReverse="^""False"^""/><DoubleAnimation Storyboard.TargetProperty="^""Opacity"^"" From="^""0"^"" To="^""1"^"" Duration="^""0:0:2"^""/></Storyboard></BeginStoryboard></EventTrigger></Button.Triggers></Button></Canvas></Grid><Window.TaskbarItemInfo><TaskbarItemInfo/></Window.TaskbarItemInfo></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$window=[Windows.Markup.XamlReader]::Load($reader);$window.Title='ZipRipper';$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage;$bitmap='%LOGO:'=''%';$window.Icon=$bitmap;$window.TaskbarItemInfo.Overlay=$bitmap;$window.TaskbarItemInfo.Description=$window.Title;$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$b=$Window.FindName("^""Start"^"");$b.Background = "^""#333333"^"";$b.Foreground="^""#eeeeee"^"";$b.FontSize="^""12"^"";$b.FontWeight="^""Bold"^"";$b.Add_MouseEnter({$b.Background="^""#eeeeee"^"";$b.Foreground="^""#333333"^""});$b.Add_MouseLeave({$b.Background="^""#333333"^"";$b.Foreground="^""#eeeeee"^""});$b.Add_Click({write-host 'Start';Exit});$b2=$Window.FindName("^""Quit"^"");$b2.Background="^""#333333"^"";$b2.Foreground="^""#eeeeee"^"";$b2.FontSize="^""12"^"";$b2.FontWeight="^""Bold"^"";$b2.Add_MouseEnter({$b2.Background="^""#eeeeee"^"";$b2.Foreground="^""#333333"^""});$b2.Add_MouseLeave({$b2.Background="^""#333333"^"";$b2.Foreground="^""#eeeeee"^""});$b2.Add_Click({write-host 'Quit';Exit});$b3=$Window.FindName("^""Offline"^"");$b3.Opacity="^""0"^"";$b3.Add_Click({$b3m=New-Object -ComObject Wscript.Shell;$b3a=$b3m.Popup('Create [zr-offline.txt] for Offline Mode?',0,'Offline Mode Builder',0x1);if($b3a -eq 1){write-host 'Offline';Exit}});$b4=$Window.FindName("^""Cleanup"^"");$b4.Opacity="^""0"^"";$b4.Add_Click({$b4m=New-Object -ComObject Wscript.Shell;$b4a=$b4m.Popup("^""Cleanup ALL resume data?"^"",0,'Clear InProgress Jobs',0x1);if($b4a -eq 1){if(Test-Path -Path '%AppData:'=''%\ZR-InProgress'){Remove-Item '%AppData:'=''%\ZR-InProgress' -Recurse -force -ErrorAction SilentlyContinue;$b4m2=New-Object -ComObject Wscript.Shell;$b4m2.Popup("^""ALL Jobs Cleared"^"",0,'Clear InProgress Jobs',0x0)} else {$b4m3=New-Object -ComObject Wscript.Shell;$b4m3.Popup('There are no jobs to clear',0,'Clear InProgress Jobs',0x0)}}});$window.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)"`) DO SET %1=%%#
EXIT /b

:CLEANUP
IF EXIST "%ProgramData%\JtR" >nul 2>&1 RD "%ProgramData%\JtR" /S /Q
IF EXIST "%ProgramData%\zr-offline.txt" >nul 2>&1 DEL "%ProgramData%\zr-offline.txt" /F /Q
IF EXIST "%ProgramData%\7zExtra.7z" >nul 2>&1 DEL "%ProgramData%\7zExtra.7z" /F /Q
IF EXIST "%ProgramData%\7zr.exe" >nul 2>&1 DEL "%ProgramData%\7zr.exe" /F /Q
IF EXIST "%ProgramData%\perlportable.zip" >nul 2>&1 DEL "%ProgramData%\perlportable.zip" /F /Q
IF EXIST "%ProgramData%\winX64_1_JtR.7z" >nul 2>&1 DEL "%ProgramData%\winX64_1_JtR.7z" /F /Q
IF EXIST "%ProgramData%\zipripper.png" >nul 2>&1 DEL "%ProgramData%\zipripper.png" /F /Q
IF EXIST "%ProgramData%\launcher.ZipRipper" >nul 2>&1 DEL "%ProgramData%\launcher.ZipRipper" /F /Q
IF EXIST "%ProgramData%\ztmp\*" >nul 2>&1 RD "%ProgramData%\ztmp" /S /Q
IF "%1"=="" >nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F&(GOTO) 2>nul&DEL "%~f0"/F /Q>nul&EXIT
EXIT /b

:BUILD
IF EXIST "%ProgramData%\ztmp\*" >nul 2>&1 RD "%ProgramData%\ztmp" /S /Q
>nul 2>&1 MD "%ProgramData%\ztmp"
>nul 2>&1 COPY /Y "%ProgramData%\zipripper.png" "%ProgramData%\ztmp\104"
PUSHD "%ProgramData%\ztmp"
(
ECHO .new Cabinet
ECHO .Set Cabinet=ON
ECHO .Set CabinetFileCountThreshold=0
ECHO .Set ChecksumWidth=1
ECHO .Set ClusterSize=CDROM
ECHO .Set LongSourceFileNames=ON
ECHO .Set CompressionType=LZX
ECHO .Set CompressionLevel=7
ECHO .Set CompressionMemory=21
ECHO .Set DiskDirectoryTemplate=
ECHO .Set FolderFileCountThreshold=0
ECHO .Set FolderSizeThreshold=0
ECHO .Set GenerateInf=ON
ECHO .Set InfFileName=nul
ECHO .Set MaxCabinetSize=0
ECHO .Set MaxDiskFileCount=0
ECHO .Set MaxDiskSize=0
ECHO .Set MaxErrors=0
ECHO .Set ReservePerCabinetSize=0
ECHO .Set ReservePerDataBlockSize=0
ECHO .Set ReservePerFolderSize=0
ECHO .Set RptFileName=nul
ECHO .Set UniqueFiles=ON
ECHO .Set SourceDir=.
ECHO 100 "7zExtra.7z"
ECHO 101 "7zr.exe"
ECHO 102 "perlportable.zip"
ECHO 103 "winX64_1_JtR.7z"
ECHO 104 "zipripper.png"
)>"%ProgramData%\ztmp\offline.config"
POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^""Building [zr-offline.txt]"^"" Height="^""75"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""3"^"" Text="^"" Initializing..."^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""28"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress"^"" Foreground="^""#FF0000"^""/><TextBlock Name="^""Info2"^"" Canvas.Top="^""38"^"" Text="^"" Getting Resources (Stage 1/2)"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""63"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress2"^"" Foreground="^""#FF0000"^""/></Canvas><Window.TaskbarItemInfo><TaskbarItemInfo/></Window.TaskbarItemInfo></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage;$bitmap='%ProgramData%\zipripper.png';$form.Icon=$bitmap;$form.TaskbarItemInfo.Overlay=$bitmap;$form.TaskbarItemInfo.Description=$form.Title;$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$progressBar=$form.FindName("^""Progress"^"");$progressTotal=$form.FindName("^""Progress2"^"");$info=$form.FindName("^""Info"^"");$info2=$form.FindName("^""Info2"^"");function Update-Gui (){$form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})};function Build () {$info.Text=' Downloading 7zr Standalone';Update-Gui;downloadFile 'https://www.7-zip.org/a/7zr.exe' '%ProgramData%\ztmp\101';$info.Text=' Downloading 7za Console';Update-Gui;downloadFile 'https://www.7-zip.org/a/7z2300-extra.7z' '%ProgramData%\ztmp\100';$info.Text=' Downloading JohnTheRipper';Update-Gui;downloadFile 'https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z' '%ProgramData%\ztmp\103';$info.Text=' Downloading Portable Perl';Update-Gui;downloadFile 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip' '%ProgramData%\ztmp\102';$progressBar.Value=0;$info.Text=' Merging resources'; $info2.Text=' Building zr-offline.txt (Stage 2/2)';$pass=1;Update-Gui;makecab.exe /F '%ProgramData%\ztmp\offline.config' /D Compress='OFF' /D CabinetNameTemplate='%ProgramData%\ztmp\zr-offline.txt'| out-string -stream | Select-String -Pattern "^""(\d{1,3})(?=[.]\d{1,2}%%)"^"" -AllMatches | ForEach-Object { $_.Matches.Value } | foreach {$progressBar.Value=$_;if($totalP2 -ge 6){$progressTotal.Value=$progressTotal.Value + 1;$totalP2=0};if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;$totalP2++};if($progressBar.Value -ge 100){$pass++};if($pass -eq 2){$info.Text="^"" Building data file"^"";if($progressBar.Value -eq 99){$pass++}};if($pass -eq 3){$info.Text="^"" Purging Cache"^""};if($progressBar.Value -ne $lastpercent2){$lastpercent2=$progressBar.Value;Update-Gui}};$progressBar.Value=100;$m=([IO.File]::ReadAllLines('%ProgramData%\launcher.ZipRipper')).Replace('"^""','');Move-Item -Path '%ProgramData%\ztmp\zr-offline.txt' -Destination "^""$m"^"" -Force;$progressTotal.Value=100;$info.Text="^"" Build Completed!"^"";Update-Gui;Sleep 3};function DownloadFile($url,$targetFile){$uri=New-Object "^""System.Uri"^"" "^""$url"^"";$request=[System.Net.HttpWebRequest]::Create($uri);$request.set_Timeout(15000);$response=$request.GetResponse();$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024);$responseStream=$response.GetResponseStream();$targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create;$buffer=new-object byte[] 10KB;$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$count;while ($count -gt 0){$targetStream.Write($buffer, 0, $count);$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$downloadedBytes + $count;$roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength) * 100);$progressBar.Value=$roundedPercent;if($totalP -ge 7){$progressTotal.Value++;$totalP=0};if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;$totalP++;Update-Gui}};$targetStream.Flush();$targetStream.Close();$targetStream.Dispose();$responseStream.Dispose()};$form.Add_ContentRendered({Build;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)">nul
POPD
>nul 2>&1 RD "%ProgramData%\ztmp" /S /Q
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup('Click OK to re-launch ZipRipper in Offline Mode, or Cancel to quit',0,'Re-Launch ZipRipper?',0x1)"`) DO SET %1=%%#
EXIT /b
