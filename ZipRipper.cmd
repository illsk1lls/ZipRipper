@ECHO OFF
REM Begin dynamic alternate wordlist info - expected format is UTF-8 .txt file inside a 7z archive -or- direct link to unarchived UTF-8 .txt file
SET WORDLISTNAME="Cyclone"
SET WORDLISTADDR="https://download.weakpass.com/wordlists/1928/cyclone_hk.txt.7z"
REM End dynamic alternate wordlist info -> Click John's mouth on the GUI to access this option <-
CALL :SINGLEINSTANCE
IF NOT "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
		ECHO FOR USE WITH x64 SYSTEMS ONLY
		ECHO/
		PAUSE
		GOTO :EOF
	) ELSE (
		ECHO UNABLE TO LAUNCH IN x86 MODE
		ECHO/
		PAUSE
		GOTO :EOF
	)
)
IF NOT "%~2"=="" (
	ECHO Multiple files are not supported. Double-click the script and use the GUI to select a file...
	ECHO/
	PAUSE
	GOTO :EOF
)
IF NOT EXIST "%~dp0zr-offline.txt" (
	SET OFFLINE=0
	CALL :CHECKCONNECTION ONLINE
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF !ONLINE! EQU 0 (
		ENDLOCAL
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
	ENDLOCAL
) ELSE (
	SET OFFLINE=1
)
>nul 2>&1 REG ADD HKCU\Software\classes\.ZipRipper\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=1\"&CALL \"%%2\" %%3"
IF /I NOT "%~dp0" == "%ProgramData%\" (
	CALL :CLEANUP STARTUP
	ECHO|(SET /p="%~dp0")>"%ProgramData%\launcher.ZipRipper"
	>nul 2>&1 COPY /Y "%~f0" "%ProgramData%"
	IF EXIST "%~dp0zr-offline.txt" (
		>nul 2>&1 COPY /Y "%~dp0zr-offline.txt" "%ProgramData%"
	)
	>nul 2>&1 FLTMC && (
		TITLE Re-Launching...
		START "" /min "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0"
		EXIT /b
	) || (
		IF NOT "%f0%"=="1" (
			TITLE Re-Launching...
			START "" /min /high "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0"
			EXIT /b
		)
	)
)
SET "NATIVE=ZIP,RAR"
SET "PERL=7z,PDF"
SET GPU=0
SET ALLOWSTART=0
CALL :CHECKWIN
CALL :CHECKGPU
IF EXIST "%ProgramData%\JtR" (
	>nul 2>&1 RD "%ProgramData%\JtR" /S /Q
)
>nul 2>&1 ATTRIB -h "%ProgramData%\BIT*.tmp"
IF EXIST "%ProgramData%\BIT*.tmp" (
	>nul 2>&1 DEL "%ProgramData%\BIT*.tmp" /F /Q
)
CALL :CENTERWINDOW
IF "%OFFLINE%"=="1" (
	CALL :OFFLINEMODE
)
IF "%~1"=="" (
	ECHO USE THE GUI TO PROCEED

:MAIN
	SET "ACTION="
	SET "WORDLIST="
	CALL :MAINMENU ACTION WORDLIST
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF "!ACTION!"=="Offline" (
		ENDLOCAL
		CALL :BUILD RELAUNCH
		SET /p OFOLDER=<"%ProgramData%\launcher.ZipRipper"
		SETLOCAL ENABLEDELAYEDEXPANSION
		IF "!RELAUNCH!"=="6" (
			TITLE Re-Launching...
			START "" /min "%ProgramData%\launcher.ZipRipper" "!OFOLDER!%~nx0"
			ENDLOCAL
			EXIT /b
		) ELSE (
			ENDLOCAL
			CALL :CLEANUP
			GOTO :EOF
		)
	)
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF NOT "!ACTION!"=="Start" (
		ENDLOCAL
		CALL :CLEANUP
	)
	IF !WORDLIST! EQU 1 (
		CALL :CHECKCONNECTION ONLINE
		IF !ONLINE! EQU 1 (
			SET "LMSG=%WORDLISTNAME:"=% wordlist selected - The wordlist will be included in the resume data"
			CALL :LISTMESSAGE "!LMSG!" "Wordlist Information:"
		) ELSE (
			SET "LMSG=Internet connection unavailable - Automatic retrieval of %WORDLISTNAME:"=% wordlist is not possible. Default and Custom wordlist options are available."
			CALL :LISTMESSAGE "!LMSG!" "Warning:"
			CALL :RESETWORDLIST
			GOTO :MAIN
		)
	)
	IF !WORDLIST! EQU 2 (
		SET "LMSG=Custom wordlist selected - The wordlist will be included in the resume data - Please select a wordlist file"
		CALL :LISTMESSAGE "!LMSG!" "Wordlist Information:"
		FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName System.Windows.Forms;$^=New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory='';Title='Select a Custom wordlist - (A text file with UTF-8 encoding)';Filter='All Supported (*.txt;*.lst)|*.txt;*.lst|TXT (*.txt)|*.txt|LST (*.lst)|*.lst'};$null=$^.ShowDialog();$Quoted='"^""' + $^^.Filename + '"^""';$Quoted"`) DO (
			SET LISTNAME=%%#
		)
		IF NOT !LISTNAME!=="" (
			IF NOT EXIST !LISTNAME! (
				CALL :RESETWORDLIST
				GOTO :MAIN
			)
			CALL :GETSIZE !LISTNAME! LISTSIZE
			IF !LISTSIZE! EQU 0 (
				CALL :ENABLEBRUTE BRUTEENABLED
				IF "!BRUTEENABLED!"=="6" (
					SET LISTNAME=BRUTE
				) ELSE (
					CALL :RESETWORDLIST
					GOTO :MAIN
				)
			)
		) ELSE (
			CALL :RESETWORDLIST
			GOTO :MAIN
		)
	)
	SET "LMSG=Please select a password protected ZIP, RAR, 7z, or PDF file"
	CALL :LISTMESSAGE "!LMSG!" "Select a target file:"
	SETLOCAL DISABLEDELAYEDEXPANSION
	CALL :GETFILE FILENAME
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF !FILENAME!=="" (
		IF DEFINED LISTNAME CALL :RESETWORDLIST
		ENDLOCAL
		GOTO :MAIN
	)
	TITLE Re-Launching...
	CALL :SETTERMINAL
	START "" "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0" "!FILENAME:"=""!"
	CALL :RESTORETERMINAL
	ENDLOCAL
	EXIT /b
)
FOR %%# IN (%NATIVE%) DO (
	IF /I "%~x1"==".%%#" (
		SET ALLOWSTART=1
		SET ISPERL=0
	)
)
FOR %%# IN (%PERL%) DO (
	IF /I "%~x1"==".%%#" (
		SET ALLOWSTART=1
		SET ISPERL=1
	)
)
IF NOT "%ALLOWSTART%"=="1" (
	CALL :CLEANUP
	GOTO :EOF
)
>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F 
>nul 2>&1 DEL "%ProgramData%\launcher.ZipRipper" /F /Q
IF EXIST "%ProgramData%\ignore.Radeon" (
	>nul 2>&1 DEL "%ProgramData%\ignore.Radeon" /F /Q
)
SET "FILETYPE=%~x1"
SET "TitleName=[ZIP-Ripper]  -  [Initializing]  -  [OpenCL #STATUS]  -  #RUNMODE Mode"
SETLOCAL ENABLEDELAYEDEXPANSION
IF !GPU! GEQ 1 (
	ENDLOCAL
	SET "TitleName=%TitleName:#STATUS=AVAILABLE%"
) ELSE (
	ENDLOCAL
	SET "TitleName=%TitleName:Initializing=CPU Mode%"
	SET "TitleName=%TitleName:#STATUS=UNAVAILABLE%"
)
SETLOCAL ENABLEDELAYEDEXPANSION
IF !OFFLINE! EQU 0 (
	ENDLOCAL
	SET "TitleName=%TitleName:#RUNMODE=Online%"
) ELSE (
	ENDLOCAL
	SET "TitleName=%TitleName:#RUNMODE=Offline%"
)
TITLE %TitleName%
IF %OFFLINE% EQU 0 (
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF !WORDLIST! EQU 1 (
		<NUL set /p=Please Wait...
		CALL :WORDLISTFILEINFO
		IF !wListOuter!=="" (
			SET wListOuter=!LISTNAME!
		)
		CALL :SINGLEDOWNLOAD %WORDLISTADDR% !wListOuter! "Downloading %WORDLISTNAME:"=% wordlist..."
		CALL :ONLINEMODE
		ECHO Ready
		ECHO/
	) ELSE (
		<NUL set /p=Please Wait...
		CALL :ONLINEMODE 
		ECHO Ready
		ECHO/
	)
) ELSE (
	IF !WORDLIST! EQU 1 (
		CALL :WORDLISTFILEINFO
		IF !wListOuter!=="" (
			SET wListOuter=!LISTNAME!
		)
		CALL :SINGLEDOWNLOAD %WORDLISTADDR% !wListOuter! "Downloading %WORDLISTNAME:"=% wordlist..."
	)
)
CALL :GETJTRREADY
ENDLOCAL
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
IF EXIST "%AppData%\ZR-InProgress\%MD5%" (
	CALL :RESUMEDECIDE ISRESUME
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF "!ISRESUME!"=="6" (
		ENDLOCAL
		>nul 2>&1 MOVE /Y "%AppData%\ZR-InProgress\%MD5%\*.*" "%ProgramData%\JtR\run\"
		CALL :CHECKRESUMENAME %1
		SET RESUME=1
		GOTO :STARTJTR
	) ELSE (
		ENDLOCAL
		>nul 2>&1 RD "%AppData%\ZR-InProgress\%MD5%" /S /Q
	)
)
SET ZIP2=0
SET PROTECTED=1
SET HSIZE=0
CALL :HASH%FILETYPE% %1
ECHO Done
ECHO/
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT "!PROTECTED!"=="1" (
	SETLOCAL DISABLEDELAYEDEXPANSION
	CALL :NOTSUPPORTED %1 "%ERRORMSG%"
	ENDLOCAL
	CALL :CLEANUP
	GOTO :EOF
)
IF DEFINED LISTNAME (
	IF !WORDLIST! EQU 2 (
		IF "!LISTNAME!"=="BRUTE" (
			<NUL set /p=Enabling BruteForce Mode...
			ECHO Ready
		) ELSE (
			<NUL set /p=Preparing Custom wordlist...
			>nul 2>&1 COPY /Y !LISTNAME! "%ProgramData%\JtR\run\password.lst"
			ECHO Loaded			
		)
	) ELSE (
		<NUL set /p=Preparing %WORDLISTNAME:"=% wordlist...
		>nul 2>&1 MOVE /Y !LISTNAME! "%ProgramData%\JtR\run\password.lst"
		ECHO Loaded
	)
	CALL :WAIT 2
) ELSE (
	<NUL set /p=Using Default wordlist...
	CALL :WAIT 1
	ECHO Loaded
	CALL :WAIT 2
)

:STARTJTR
CLS
ECHO Running JohnTheRipper...
ECHO/
IF "%RESUME%"=="1" (
	ECHO Resuming Session...
	ECHO/
	CALL :SETSTATUSANDFLAGS
	john --restore
) ELSE (
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF "!LISTNAME!"=="BRUTE" (
	john "%ProgramData%\JtR\run\pwhash" --incremental=ASCII.chr !FLAG!	
	) ELSE (
	john --wordlist="%ProgramData%\JtR\run\password.lst" --rules=single,all "%ProgramData%\JtR\run\pwhash" !FLAG!
	)
	ENDLOCAL
)
CALL :GETSIZE "%ProgramData%\JtR\run\john.pot" POTSIZE
CALL :SAVELOCATION UserDesktop
SETLOCAL ENABLEDELAYEDEXPANSION
IF !POTSIZE! GEQ 1 (
	ENDLOCAL
	ECHO/
	<NUL set /p=Generating Password File...
	CALL :SAVEFILE %1
	IF EXIST "%AppData%\ZR-InProgress\%MD5%" (
		>nul 2>&1 RD "%AppData%\ZR-InProgress\%MD5%" /S /Q
	)
	ECHO Done
	ECHO/
	ECHO Passwords saved to: "%UserDesktop%\ZipRipper-Passwords.txt"
	SETLOCAL ENABLEDELAYEDEXPANSION
	CALL :GETSIZE "!UserDesktop!\ZipRipper-Passwords.txt" PWSIZE
	IF !PWSIZE! LEQ 1600 (
		ENDLOCAL
		CALL :DISPLAYINFOA
	) ELSE (
		ENDLOCAL
		CALL :DISPLAYINFOB
	)
) ELSE (
	ENDLOCAL	
	ECHO/
	CALL :SETRESUME %1
)
ECHO/
PAUSE
POPD
CALL :CLEANUP
GOTO :EOF

:GETMD5
SET "MD5FILE=%~1"
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=Resolve-Path '%MD5FILE:'=''%';$md5=new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider;$f=[System.IO.File]::Open($^,[System.IO.Filemode]::Open,[System.IO.FileAccess]::Read);try{[System.BitConverter]::ToString($md5.ComputeHash($f)).Replace('-','').ToLower()}finally{$f.Dispose()}"`) DO (
	SET %2=%%#
)
EXIT /b

:RESUMEDECIDE
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup('Would you like to resume the job? (Click NO to clear the resume data and start over)',0,'Resume Data Found',32+4)"`) DO (
	SET %1=%%#
)
EXIT /b

:SETRESUME
IF NOT EXIST "%ProgramData%\JtR\run\john.rec" (
	ECHO Resume is UNAVAILABLE for this file ;^(
) ELSE (
	ECHO Resume is available for the next session...
	IF NOT EXIST "%AppData%\ZR-InProgress\%MD5%" (
		MD "%AppData%\ZR-InProgress\%MD5%"
	)
	>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\pwhash" "%AppData%\ZR-InProgress\%MD5%"
	>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.pot" "%AppData%\ZR-InProgress\%MD5%"
	>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.rec" "%AppData%\ZR-InProgress\%MD5%"
	IF /I EXIST "%ProgramData%\JtR\run\john.*.rec" (
		>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.*.rec" "%AppData%\ZR-InProgress\%MD5%"
	)
	>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\john.log" "%AppData%\ZR-InProgress\%MD5%"
	>nul 2>&1 MOVE /Y "%ProgramData%\JtR\run\password.lst" "%AppData%\ZR-InProgress\%MD5%"
)
EXIT /b

:WAIT
SET /A TIMER=%~1+1
>nul 2>&1 PING 127.0.0.1 -n %TIMER%
EXIT /b

:NOTSUPPORTED
CLS
ECHO "%~1" %~2
ECHO/
PAUSE
EXIT /b 

:ONLINEMODE
SET P=3
SET PT=11
IF "%ISPERL%"=="1" (
	SET P=4
	SET PT=8
	SET "PERL2=$info.Text=' Downloading Portable Perl';Update-Gui;downloadFile 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip' '%ProgramData%\perlportable.zip';"
)
POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^"" Initializing..."^"" Height="^""75"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""3"^"" Text="^"" Initializing..."^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""28"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress"^"" Foreground="^""#FF0000"^""/><TextBlock Name="^""Info2"^"" Canvas.Top="^""38"^"" Text="^"" Getting Resources (Online Mode)"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""63"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress2"^"" Foreground="^""#FF0000"^""/></Canvas><Window.TaskbarItemInfo><TaskbarItemInfo/></Window.TaskbarItemInfo></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage;$bitmap='%LOGO:'=''%';$form.Icon=$bitmap;$form.TaskbarItemInfo.Overlay=$bitmap;$form.TaskbarItemInfo.Description=$form.Title;$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$progressBar=$form.FindName("^""Progress"^"");$progressTotal=$form.FindName("^""Progress2"^"");$info=$form.FindName("^""Info"^"");$info2=$form.FindName("^""Info2"^"");function Update-Gui(){$form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})};function GetResources(){$info.Text=' Initializing...';$progressTotal.Value=%PT%;Update-Gui;$info.Text=' Downloading 7zr Standalone';Update-Gui;downloadFile 'https://www.7-zip.org/a/7zr.exe' '%ProgramData%\7zr.exe';$info.Text=' Downloading 7za Console';Update-Gui;downloadFile 'https://www.7-zip.org/a/7z2300-extra.7z' '%ProgramData%\7zExtra.7z';$info.Text=' Downloading JohnTheRipper';Update-Gui;downloadFile 'https://github.com/openwall/john-packages/releases/download/bleeding/winX64_1_JtR.7z' '%ProgramData%\winX64_1_JtR.7z';%PERL2%$progressTotal.Value=100;$info.Text="^"" Ready..."^"";Update-Gui};function DownloadFile($url,$targetFile){$uri=New-Object "^""System.Uri"^"" "^""$url"^"";$request=[System.Net.HttpWebRequest]::Create($uri);$request.set_Timeout(15000);$response=$request.GetResponse();$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024);$responseStream=$response.GetResponseStream();$targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create;$buffer=new-object byte[] 10KB;$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$count;while ($count -gt 0){$targetStream.Write($buffer, 0, $count);$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$downloadedBytes + $count;$roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength) * 100);$progressBar.Value=$roundedPercent;if($totalP -ge %P%){$progressTotal.Value++;$totalP=0};if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;$totalP++;Update-Gui}};$targetStream.Flush();$targetStream.Close();$targetStream.Dispose();$responseStream.Dispose()};$form.Add_ContentRendered({GetResources;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)">nul
EXIT /b

:OFFLINEMODE
SET NEEDED=7zr.exe,7zExtra.7z,winX64_1_JtR.7z,perlportable.zip,zipripper.png
SET EXTRACT=0
<NUL set /p=Offline mode enabled
FOR %%# IN (%NEEDED%) DO (
	IF /I NOT EXIST "%~dp0%%#" (
		SET EXTRACT=1
	)
)
IF NOT "%EXTRACT%"=="1" (
	<NUL set /p=, checking resources...
) ELSE (
	<NUL set /p=, preparing resources...
	PUSHD "%~dp0"
	POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^"" Initializing..."^"" Height="^""37"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""10"^"" Canvas.Left="^""23"^"" Text="^"" Initializing... (Offline Mode)"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/></Canvas></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});function ExtractFile(){&expand -R zr-offline.txt -F:* .};$form.Add_ContentRendered({ExtractFile;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)">nul
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
IF EXIST !wListOuter! (
	CALL :EXTENSION !wListOuter! WLEXT
	IF /I "!WLEXT!"==".7z" (
		"%ProgramData%\7zr.exe" x -y !wListOuter! -o"%ProgramData%\">nul
		>nul 2>&1 DEL !wListOuter! /F /Q
	)
)
IF "%ISPERL%"=="1" (
	"%ProgramData%\JtR\7za.exe" x -y "%ProgramData%\perlportable.zip" -o"%ProgramData%\JtR\run">nul
)
IF EXIST "%ProgramData%\perlportable.zip" (
	>nul 2>&1 DEL "%ProgramData%\perlportable.zip" /F /Q
)
IF EXIST "%ProgramData%\zr-offline.txt" (
	>nul 2>&1 DEL "%ProgramData%\zr-offline.txt" /F /Q
)
>nul 2>&1 DEL "%ProgramData%\winX64_1_JtR.7z" /F /Q
>nul 2>&1 DEL "%ProgramData%\7zr.exe" /F /Q
>nul 2>&1 DEL "%ProgramData%\7zExtra.7z" /F /Q
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

:CHECKRESUMENAME
FOR /F "tokens=1 delims=:/" %%# IN (pwhash) DO (
	IF NOT "%~nx1"=="%%#" (
		SET ALT=1
		SET "OLDNAME=%%#"
	) ELSE (
		SET ALT=0
	)
)
SET "NEWNAME=%~nx1"
IF "%ALT%"=="1" (
	POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup("^""This file has been renamed since the initial session. The filename will be updated in the saved session data.`n`nInitial file name: %OLDNAME%`n`nCurrent file name: %~nx1`n`nIt is recommended that you do not change the file name after the initial session to avoid potential issues, but it is not a requirement, and the session is able to resume anyway..."^"",0,'WARNING: File name change detected!',0x0);$update=[System.IO.File]::ReadAllText('%ProgramData%\JtR\run\pwhash').Replace('%OLDNAME:'=''%','%NEWNAME:'=''%');[System.IO.File]::WriteAllText('%ProgramData%\JtR\run\pwhash', $update)">nul
)
EXIT /b

:HASH.ZIP
zip2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>"%ProgramData%\JtR\run\statusout"
FOR /F %%# IN ("%ProgramData%\JtR\run\pwhash") DO (
	SET HSIZE=%%~z#
)
IF %HSIZE% EQU 0 (
	SET PROTECTED=0
	SET "ERRORMSG=is not password protected.."
	FOR /F "usebackq tokens=*" %%# IN (`TYPE "%ProgramData%\JtR\run\statusout" ^| findstr /I /C^:"Did not find"`) DO (
		SET PROTECTED=2
		SET "ERRORMSG=encryption type is not supported.. (not a ZIPfile)"
	)
)
CALL :SETSTATUSANDFLAGS
EXIT /b

:HASH.RAR
rar2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>"%ProgramData%\JtR\run\statusout"
FOR /F %%# IN ("%ProgramData%\JtR\run\pwhash") DO (
	SET HSIZE=%%~z#
)
IF %HSIZE% EQU 0 (
	FOR /F "usebackq tokens=*" %%# IN (`TYPE "%ProgramData%\JtR\run\statusout" ^| findstr /I /C^:"Did not find"`) DO (
		SET PROTECTED=0
		SET "ERRORMSG=is not password protected.."
	)
	FOR /F "usebackq tokens=*" %%# IN (`TYPE "%ProgramData%\JtR\run\statusout" ^| findstr /I /C^:"not supported"`) DO (
		SET PROTECTED=2
		SET "ERRORMSG=encryption type is not supported.. (old filetype)"
	)
) ELSE (
	FOR /F "tokens=4 delims=*" %%# IN (pwhash) DO (
		IF "%%#"=="00000000" (
			SET PROTECTED=2
			SET "ERRORMSG=encryption type is not supported.."
		)
	)
)
CALL :SETSTATUSANDFLAGS
EXIT /b

:HASH.7z
CALL portableshell.bat 7z2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>"%ProgramData%\JtR\run\statusout"
FOR /F %%# IN ("%ProgramData%\JtR\run\pwhash") DO (
	SET HSIZE=%%~z#
)
IF %HSIZE% EQU 0 (
	SET PROTECTED=0
	SET "ERRORMSG=is not password protected.."
) ELSE (
	FOR /F "usebackq tokens=*" %%# IN (`TYPE statusout ^| findstr /I /C^:"not supported"`) DO (
		SET PROTECTED=2
		SET "ERRORMSG=encryption type is not supported.."
	)
)
CALL :SETSTATUSANDFLAGS
EXIT /b

:HASH.PDF
CALL portableshell.bat pdf2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
POWERSHELL -nop -c "$^=[regex]::Match((gc pwhash),'^(.+\/)(?i)(.*\.pdf)(.+$)');$^.Groups[2].value+$^.Groups[3].value|sc pwhash">nul 2>&1
FOR /F %%# IN ("%ProgramData%\JtR\run\pwhash") DO (
	SET HSIZE=%%~z#
)
IF %HSIZE% LSS 8000 FOR /F "usebackq tokens=*" %%# IN (`TYPE pwhash ^| findstr /I /C^:"not encrypted!"`) DO (
	SET PROTECTED=0
	SET "ERRORMSG=is not password protected.."
)
CALL :SETSTATUSANDFLAGS
EXIT /b

:SETSTATUSANDFLAGS
IF /I "%FILETYPE%"==".zip" (
	FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (
		IF /I "%%#"=="zip2" (
			SETLOCAL ENABLEDELAYEDEXPANSION
			IF !GPU! GEQ 1 (
				ENDLOCAL
				SET "FLAG=--format=ZIP-opencl"
				SET ZIP2=1
				CALL :OPENCLENABLED
			) ELSE (
				ENDLOCAL
				IF NOT "%RESUME%"=="1" (			
					CALL :CPUMODESPLIT
				)
				SET ZIP2=1
			)
		)
		IF /I "%%#"=="pkzip" (
			SET "TitleName=%TitleName:Initializing=CPU Mode%"
			SET "TitleName=%TitleName:AVAILABLE=UNSUPPORTED Filetype%"
			TITLE %TitleName%
			IF NOT "%RESUME%"=="1" (			
				CALL :CPUMODESPLIT
			)
		) 
	)
)
IF /I "%FILETYPE%"==".rar" (
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF !GPU! GEQ 1 (
		ENDLOCAL
		FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (
			IF /I "%%#"=="rar" (
				SET "FLAG=--format=rar-opencl"
				CALL :OPENCLENABLED
			)
			IF /I "%%#"=="rar3" (
				SET "FLAG=--format=rar-opencl"
				CALL :OPENCLENABLED
			)
			IF /I "%%#"=="rar5" (
				SET "FLAG=--format=RAR5-opencl"
				CALL :OPENCLENABLED
			)
		)
		
	) ELSE (
		ENDLOCAL
		IF NOT "%RESUME%"=="1" (
			CALL :CPUMODESPLIT
		)
	)
)
IF /I "%FILETYPE%"==".7z" (
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF !GPU! GEQ 1 (
		ENDLOCAL
		SET "FLAG=--format=7z-opencl"
		CALL :OPENCLENABLED
	) ELSE (
		ENDLOCAL
		IF NOT "%RESUME%"=="1" (
			CALL :CPUMODESPLIT
		)
	)
)
IF /I "%FILETYPE%"==".pdf" (
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF !GPU! GEQ 1 (
		ENDLOCAL
		SET "TitleName=%TitleName:Initializing=CPU Mode%"
		SET "TitleName=%TitleName:AVAILABLE=UNSUPPORTED Filetype%"
		TITLE %TitleName%
	) ELSE (
		ENDLOCAL
	)
	IF NOT "%RESUME%"=="1" (
		CALL :CPUMODESPLIT
	)
)
EXIT /b

:OPENCLENABLED
SET "TitleName=%TitleName:Initializing=GPU Mode%"
SET "TitleName=%TitleName:AVAILABLE=ENABLED%"
TITLE %TitleName%
EXIT /b

:GETSIZE
SET "%2=%~z1"
IF %~z1==[] (
	SET "%2=0"
)
EXIT /b

:TRIMWHITESPACE
SETLOCAL ENABLEDELAYEDEXPANSION
SET TRIM=%*
FOR /f "tokens=1*" %%# in ("!TRIM!") DO (
	ENDLOCAL
	SET "%1=%%$"
)
EXIT /b

:SINGLE
FOR /F "tokens=2 delims=:" %%# IN (john.pot) DO (
	ECHO|(SET /p="%%# - [%~nx1]"&ECHO/)>>"%UserDesktop%\ZipRipper-Passwords.txt"
)
EXIT /b

:MULTI
FOR /F "tokens=1,5 delims=*" %%# IN (pwhash) DO (
	FOR /F "tokens=1,3 delims=$" %%# IN ("%%#%%$") DO (
		IF NOT DEFINED # (
			FOR /F "tokens=2 delims=:" %%# IN ("%%#%%$") DO (
				CALL :TRIMWHITESPACE %%#
				CALL :CHECKLENGTH %%# #
			)
		)
		FOR /F "tokens=1,2 delims=:" %%# IN ("%%#%%$") DO (
			SETLOCAL ENABLEDELAYEDEXPANSION
			FOR /F "usebackq tokens=*" %%_ IN (`POWERSHELL -nop -c "$^^=gc john.pot|%%{$_ -Replace '^^.+?\*.\*([a-z\d]{!#!})\*.+:(.*)$',"^""`$1:`$2"^"";Write-Host $_}"`) DO (
				ENDLOCAL
				FOR /F "tokens=5 delims=*" %%` IN ("%%_") DO (
					CALL :TRIMWHITESPACE $ %%$
					SETLOCAL ENABLEDELAYEDEXPANSION
					FOR /F "tokens=1* delims=:" %%Y IN ("%%_") DO (
						IF "!$!"=="%%`" (
							ENDLOCAL
							ECHO|(SET /p="%%Z - [%%#]"&ECHO/)>>"%UserDesktop%\ZipRipper-Passwords.txt"
						) ELSE (
							ENDLOCAL
						)
					)
				)
			)		
		)
	)
)
EXIT /b

:CHECKLENGTH
(   
	SETLOCAL ENABLEDELAYEDEXPANSION
	(SET^ L=!%~1!)
	IF DEFINED L (
		SET "LENGTH=1"
		FOR %%P IN (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) DO (
			IF "!L:~%%P,1!" NEQ "" ( 
			SET /A "LENGTH+=%%P"
			SET "L=!L:~%%P!"
			)
		)
	) ELSE (
		SET LENGTH=0
	)
)
( 
	ENDLOCAL
	SET "%~2=%LENGTH%"
	EXIT /b
)

:EXTENSION
SET %2=%~x1
EXIT /b

:RENAMEOLD
IF EXIST "%UserDesktop%\ZipRipper-Passwords.%R%.txt" (
	SET /A R+=1
	GOTO :RENAMEOLD
) ELSE (
	REN "%UserDesktop%\ZipRipper-Passwords.txt" "ZipRipper-Passwords.%R%.txt"
)
EXIT /b

:DISPLAYINFOA
CALL :SETTERMINAL
START /min "Loading Results..." POWERSHELL -nop -c "Add-Type -MemberDefinition '[DllImport("^""User32.dll"^"")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Namespace Win32 -Name Functions;$Min=[Win32.Functions]::ShowWindow((Get-Process -Id $PID).MainWindowHandle,0);$^={$Notify=[PowerShell]::Create().AddScript({$Audio=New-Object System.Media.SoundPlayer;$Audio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$Audio.playsync()});$rs=[RunspaceFactory]::CreateRunspace();$rs.ApartmentState="^""STA"^"";$rs.ThreadOptions="^""ReuseThread"^"";$rs.Open();$Notify.Runspace=$rs;$Notify.BeginInvoke()};&$^;$Msg=@();foreach($line in Get-Content '%UserDesktop%\ZipRipper-Passwords.txt'){if($null -eq $Msg){$Msg+=$line}else{$Msg+=$line + "^""`n"^""}};$Msg+="^""Save Location:`n"^"";$Msg+="^"""^"""^""%UserDesktop%\ZipRipper-Passwords.txt"^"""^"""^"";$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup($Msg,0,'Message from ZIP-Ripper',0x0)">nul
CALL :RESTORETERMINAL
EXIT /b

:DISPLAYINFOB
CALL :SETTERMINAL
START /min "Loading Results..." POWERSHELL -nop -c "Add-Type -MemberDefinition '[DllImport("^""User32.dll"^"")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Namespace Win32 -Name Functions;$Min=[Win32.Functions]::ShowWindow((Get-Process -Id $PID).MainWindowHandle,0);$^={$Notify=[PowerShell]::Create().AddScript({$Audio=New-Object System.Media.SoundPlayer;$Audio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$Audio.playsync()});$rs=[RunspaceFactory]::CreateRunspace();$rs.ApartmentState="^""STA"^"";$rs.ThreadOptions="^""ReuseThread"^"";$rs.Open();$Notify.Runspace=$rs;$Notify.BeginInvoke()};&$^;$Msg=@();$Msg+="^""[ZIP-Ripper] - FOUND PASSWORDS`n"^"";$Msg+="^"" %DATE% + %TIME%`n"^"";$Msg+="^""==============================`n"^"";$Msg+="^""`n"^"";$Msg+="^""TOO MANY TO LIST`n"^"";$Msg+="^""`n"^"";$Msg+="^""==============================`n"^"";$Msg+="^""Save Location:`n"^"";$Msg+="^"""^"""^""%UserDesktop%\ZipRipper-Passwords.txt"^"""^"""^"";$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup($Msg,0,'Message from ZIP-Ripper',0x0)">nul
CALL :RESTORETERMINAL
EXIT /b

:CHECKCONNECTION
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$ProgressPreference='SilentlyContinue';irm http://www.msftncsi.com/ncsi.txt;$ProgressPreference='Continue'"`) DO (
	IF "%%#"=="Microsoft NCSI" (
		SET "%1=1"
	) ELSE (
		SET "%1=0"
	)
)
EXIT /b

:SINGLEINSTANCE
TASKLIST /V /NH /FI "imagename eq cmd.exe"|FINDSTR /I /C^:"ZIP-Ripper">nul
IF NOT %errorlevel%==1 (
	POWERSHELL -nop -c "$^={$Notify=[PowerShell]::Create().AddScript({$Audio=New-Object System.Media.SoundPlayer;$Audio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$Audio.playsync()});$rs=[RunspaceFactory]::CreateRunspace();$rs.ApartmentState="^""STA"^"";$rs.ThreadOptions="^""ReuseThread"^"";$rs.Open();$Notify.Runspace=$rs;$Notify.BeginInvoke()};&$^;$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup("^""ZipRipper is already running!"^"",0,'ERROR:',0x10)">nul&EXIT
)
TITLE [ZIP-Ripper] Launching...
EXIT /b

:CENTERWINDOW
>nul 2>&1 POWERSHELL -nop -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport("^""user32.dll"^"")]public static extern void SetProcessDPIAware();[DllImport("^""shcore.dll"^"")]public static extern void SetProcessDpiAwareness(int value);[DllImport("^""kernel32.dll"^"")]public static extern IntPtr GetConsoleWindow();[DllImport("^""user32.dll"^"")]public static extern void GetWindowRect(IntPtr hwnd,int[] rect);[DllImport("^""user32.dll"^"")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport("^""user32.dll"^"")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport("^""user32.dll"^"")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport("^""user32.dll"^"")]public static extern int SetWindowPos(IntPtr hwnd,IntPtr hwndAfterZ,int x,int y,int w,int h,int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try{$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)}catch{$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7]-$moninf[5];$monheight=$moninf[8]-$moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2]-$wrect[0];$winheight=$wrect[3]-$wrect[1];$x=[int][math]::Round($moninf[5]+$monwidth/2-$winwidth/2);$y=[int][math]::Round($moninf[6]+$monheight/2-$winheight/2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd,[IntPtr]::Zero,$x,$y,0,0,$SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
EXIT /b

:GETFILE
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName System.Windows.Forms;$^=New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory='';Title='Select a password protected ZIP, RAR, 7z or PDF...';Filter='All Supported (*.zip;*.rar;*.7z;*.pdf)|*.zip;*.rar;*.7z;*.pdf|ZIP (*.zip)|*.zip|RAR (*.rar)|*.rar|7-Zip (*.7z)|*.7z|PDF (*.pdf)|*.pdf'};$null=$^.ShowDialog();$Quoted='"^""' + $^^.Filename + '"^""';$Quoted"`) DO (
	SET "%1=%%#"
)
EXIT /b

:WORDLISTFILEINFO
FOR /F "usebackq tokens=1,2" %%# IN (`POWERSHELL "$^=[regex]::Match('%WORDLISTADDR:"=%', '.*\/((.*)\..*)$');$^.Groups[1].Value+' '+$^.Groups[2].Value"`) DO (
	CALL :EXTENSION %%# EXT
	IF /I NOT "!EXT!"==".7z" (
		IF /I "!EXT!"==".txt" (
			SET wListOuter=""
			SET wListInner="%%#"
		)
	) ELSE (
		SET wListOuter="%%#"
		SET CHECK="%%$"
		IF /I "!CHECK:~-5,-1!"==".txt" (
			SET wListInner="%%$"
		) ELSE (
			SET wListInner="%%$.txt"
		)
	)
)
SET LISTNAME="%ProgramData%\!wListInner:"=!"
IF NOT !wListOuter!=="" (
	SET wListOuter="%ProgramData%\!wListOuter:"=!"
)
EXIT /b

:RESETWORDLIST
SET "LISTNAME="
CALL :LISTMESSAGE "Wordlist settings reset to default" "Wordlist Info:"
EXIT /b

:LISTMESSAGE
POWERSHELL -nop -c "$^={$Notify=[PowerShell]::Create().AddScript({$Audio=New-Object System.Media.SoundPlayer;$Audio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav';$Audio.playsync()});$rs=[RunspaceFactory]::CreateRunspace();$rs.ApartmentState="^""STA"^"";$rs.ThreadOptions="^""ReuseThread"^"";$rs.Open();$Notify.Runspace=$rs;$Notify.BeginInvoke()};&$^;$PopUp=New-Object -ComObject Wscript.Shell;$PopUp.Popup("^""%~1"^"",0,'%~2',0 + 64)">nul
EXIT /b

:ENABLEBRUTE
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup('Would you like to enable bruteforce mode? (Click NO to restore default settings and return to the menu)',0,'The selected wordlist file is empty',32+4)"`) DO (
	SET %1=%%#
)
EXIT /b

:SINGLEDOWNLOAD
POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^"" %~3"^"" Height="^""37"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""3"^"" Text="^"" %~3"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""28"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress"^"" Foreground="^""#FF0000"^""/></Canvas></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$progressBar=$form.FindName("^""Progress"^"");function Update-Gui (){$form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})};function DownloadFile($url,$targetFile){$uri=New-Object "^""System.Uri"^"" "^""$url"^"";$request=[System.Net.HttpWebRequest]::Create($uri);$request.set_Timeout(15000);$response=$request.GetResponse();$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024);$responseStream=$response.GetResponseStream();$targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create;$buffer=new-object byte[] 10KB;$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$count;while ($count -gt 0){$targetStream.Write($buffer,0,$count);$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$downloadedBytes+$count;$roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024))/$totalLength)*100);$progressBar.Value=$roundedPercent;if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;Update-Gui}};$targetStream.Flush();$targetStream.Close();$targetStream.Dispose();$responseStream.Dispose()};$form.Add_ContentRendered({downloadFile '%~1' '%~2';Sleep 1;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)"
EXIT /b

:MAINMENU
SET "LOGO=%ProgramData%\zipripper.png"
IF /I NOT EXIST "%LOGO%" (
	CALL :SINGLEDOWNLOAD "https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/zipripper.png" "%LOGO%" "Initializing..."
)
FOR /F "usebackq delims=, tokens=1,2*" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;function wlist(){Switch($showL){0{$D.Visibility="^""Visible"^"";$R.Visibility="^""Visible"^"";$C.Visibility="^""Visible"^"";$global:showL="^""1"^""}1{$D.Visibility="^""Collapsed"^"";$R.Visibility="^""Collapsed"^"";$C.Visibility="^""Collapsed"^"";$global:showL="^""0"^""}}};[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Background="^""Transparent"^"" AllowsTransparency="^""True"^"" Width="^""285"^"" Height="^""324"^""><Window.Resources><ControlTemplate x:Key="^""nM"^"" TargetType="^""Button"^""><Border Background="^""{TemplateBinding Background}"^"" BorderBrush="^""{TemplateBinding BorderBrush}"^"" BorderThickness="^""{TemplateBinding BorderThickness}"^""><ContentPresenter HorizontalAlignment="^""{TemplateBinding HorizontalContentAlignment}"^"" VerticalAlignment="^""{TemplateBinding VerticalContentAlignment}"^""/></Border><ControlTemplate.Triggers><Trigger Property="^""IsEnabled"^"" Value="^""False"^""><Setter Property="^""Background"^"" Value="^""{x:Static SystemColors.ControlLightBrush}"^""/><Setter Property="^""Foreground"^"" Value="^""{x:Static SystemColors.GrayTextBrush}"^""/></Trigger></ControlTemplate.Triggers></ControlTemplate></Window.Resources><Grid><Grid.RowDefinitions><RowDefinition Height="^""298"^""/><RowDefinition Height="^""*"^""/></Grid.RowDefinitions><Grid.Background><ImageBrush ImageSource="^""%LOGO%"^""/></Grid.Background><Grid.Triggers><EventTrigger RoutedEvent="^""Loaded"^""><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="^""Background.Opacity"^"" From="^""0"^"" To="^""1"^"" Duration="^""0:0:1"^""/></Storyboard></BeginStoryboard></EventTrigger></Grid.Triggers><Canvas Grid.Row="^""0"^""><Button x:Name="^""Offline"^"" Canvas.Left="^""141"^"" Canvas.Top="^""56"^"" Height="^""16"^"" Width="^""26"^"" ToolTip="^""Create [zr-offline.txt]"^"" Template="^""{StaticResource nM}"^""/><Button x:Name="^""Cleanup"^"" Canvas.Left="^""138"^"" Canvas.Top="^""154"^"" Height="^""20"^"" Width="^""20"^"" ToolTip="^""Clear Resume Cache"^"" Template="^""{StaticResource nM}"^""/><Button Name="^""List"^"" Canvas.Left="^""143"^"" Canvas.Top="^""116"^"" Height="^""10"^"" Width="^""15"^"" ToolTip="^""Select Wordlist"^"" Template="^""{StaticResource nM}"^"" Opacity="^""0"^""></Button><Button Name="^""Default"^"" Canvas.Left="^""123"^"" Canvas.Top="^""130"^"" FontSize="^""11"^"" Foreground="^""#eeeeee"^"" Background="^""#333333"^"" Height="^""18"^"" Width="^""55"^"" Visibility="^""Collapsed"^"" HorizontalContentAlignment="^""Left"^"" Template="^""{StaticResource nM}"^"" Opacity="^""0.9"^"">Default</Button><Button Name="^""WL"^"" Canvas.Left="^""123"^"" Canvas.Top="^""147"^"" FontSize="^""11"^"" Foreground="^""#eeeeee"^"" Background="^""#333333"^"" Height="^""18"^"" Width="^""55"^"" Visibility="^""Collapsed"^"" HorizontalContentAlignment="^""Left"^"" Template="^""{StaticResource nM}"^"" Opacity="^""0.9"^"">%WORDLISTNAME:"=%</Button><Button Name="^""Custom"^"" Canvas.Left="^""123"^"" Canvas.Top="^""164"^"" FontSize="^""11"^"" Foreground="^""#eeeeee"^"" Background="^""#333333"^"" Height="^""18"^"" Width="^""55"^"" Visibility="^""Collapsed"^"" HorizontalContentAlignment="^""Left"^"" Template="^""{StaticResource nM}"^"" Opacity="^""0.9"^"">Custom</Button></Canvas><Canvas Grid.Row="^""1"^""><Button x:Name="^""Start"^"" Height="^""22"^"" Width="^""65"^"" Content="^""Start"^"" ToolTip="^""Click to Begin..."^"" Template="^""{StaticResource nM}"^""><Button.Triggers><EventTrigger RoutedEvent="^""Loaded"^""><BeginStoryboard><Storyboard><DoubleAnimation From="^""40"^"" To="^""65"^"" Duration="^""0:0:1"^"" Storyboard.TargetProperty="^""(Canvas.Left)"^"" AutoReverse="^""False"^""/><DoubleAnimation Storyboard.TargetProperty="^""Opacity"^"" From="^""0"^"" To="^""1"^"" Duration="^""0:0:2"^""/></Storyboard></BeginStoryboard></EventTrigger></Button.Triggers></Button></Canvas><Canvas Grid.Row="^""1"^""><Button x:Name="^""Quit"^"" Height="^""22"^"" Width="^""65"^"" Content="^""Quit"^"" ToolTip="^""Click to Exit"^"" Template="^""{StaticResource nM}"^""><Button.Triggers><EventTrigger RoutedEvent="^""Loaded"^""><BeginStoryboard><Storyboard><DoubleAnimation From="^""40"^"" To="^""65"^"" Duration="^""0:0:1"^"" Storyboard.TargetProperty="^""(Canvas.Right)"^"" AutoReverse="^""False"^""/><DoubleAnimation Storyboard.TargetProperty="^""Opacity"^"" From="^""0"^"" To="^""1"^"" Duration="^""0:0:2"^""/></Storyboard></BeginStoryboard></EventTrigger></Button.Triggers></Button></Canvas></Grid><Window.TaskbarItemInfo><TaskbarItemInfo/></Window.TaskbarItemInfo></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$window=[Windows.Markup.XamlReader]::Load($reader);$window.Title='ZipRipper';$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage;$bitmap='%LOGO:'=''%';$window.Icon=$bitmap;$window.TaskbarItemInfo.Overlay=$bitmap;$window.TaskbarItemInfo.Description=$window.Title;$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$L=$Window.FindName("^""List"^"");$D=$Window.FindName("^""Default"^"");$R=$Window.FindName("^""WL"^"");$C=$Window.FindName("^""Custom"^"");$L.Add_Click({wlist});$D.Add_MouseEnter({$D.Background="^""#eeeeee"^"";$D.Foreground="^""#333333"^""});$D.Add_MouseLeave({$D.Background="^""#333333"^"";$D.Foreground="^""#eeeeee"^""});$D.Add_Click({$global:list="^""0"^"";wlist});$R.Add_MouseEnter({$R.Background="^""#eeeeee"^"";$R.Foreground="^""#333333"^""});$R.Add_MouseLeave({$R.Background="^""#333333"^"";$R.Foreground="^""#eeeeee"^""});$R.Add_Click({$global:list="^""1"^"";wlist});$C.Add_MouseEnter({$C.Background="^""#eeeeee"^"";$C.Foreground="^""#333333"^""});$C.Add_MouseLeave({$C.Background="^""#333333"^"";$C.Foreground="^""#eeeeee"^""});$C.Add_Click({$global:list="^""2"^"";wlist});$b=$Window.FindName("^""Start"^"");$b.Background = "^""#333333"^"";$b.Foreground="^""#eeeeee"^"";$b.FontSize="^""12"^"";$b.FontWeight="^""Bold"^"";$b.Add_MouseEnter({$b.Background="^""#eeeeee"^"";$b.Foreground="^""#333333"^""});$b.Add_MouseLeave({$b.Background="^""#333333"^"";$b.Foreground="^""#eeeeee"^""});$b.Add_Click({write-host "^""Start,$list"^"";Exit});$b2=$Window.FindName("^""Quit"^"");$b2.Background="^""#333333"^"";$b2.Foreground="^""#eeeeee"^"";$b2.FontSize="^""12"^"";$b2.FontWeight="^""Bold"^"";$b2.Add_MouseEnter({$b2.Background="^""#eeeeee"^"";$b2.Foreground="^""#333333"^""});$b2.Add_MouseLeave({$b2.Background="^""#333333"^"";$b2.Foreground="^""#eeeeee"^""});$b2.Add_Click({write-host 'Quit';Exit});$b3=$Window.FindName("^""Offline"^"");$b3.Opacity="^""0"^"";$b3.Add_Click({$b3m=New-Object -ComObject Wscript.Shell;$b3a=$b3m.Popup('Create [zr-offline.txt] for Offline Mode?',0,'Offline Mode Builder',0x1);if($b3a -eq 1){write-host 'Offline';Exit}});$b4=$Window.FindName("^""Cleanup"^"");$b4.Opacity="^""0"^"";$b4.Add_Click({$b4m=New-Object -ComObject Wscript.Shell;$b4a=$b4m.Popup("^""Cleanup ALL resume data?"^"",0,'Clear InProgress Jobs',0x1);if($b4a -eq 1){if(Test-Path -Path '%AppData:'=''%\ZR-InProgress'){Remove-Item '%AppData:'=''%\ZR-InProgress' -Recurse -force -ErrorAction SilentlyContinue;$b4m2=New-Object -ComObject Wscript.Shell;$b4m2.Popup("^""ALL Jobs Cleared"^"",0,'Clear InProgress Jobs',0x0)} else {$b4m3=New-Object -ComObject Wscript.Shell;$b4m3.Popup('There are no jobs to clear',0,'Clear InProgress Jobs',0x0)}}});$list="^""0"^"";$showL="^""0"^"";$window.add_MouseLeftButtonDown({if($showL -eq 1){wlist};$window.DragMove()});$window.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)"`) DO (
	SET "%1=%%#"
	IF NOT "%%$"=="" (
		SET "%2=%%$"
	)
)
EXIT /b

:CLEANUP
IF /I EXIST "%ProgramData%\JtR" (
	>nul 2>&1 RD "%ProgramData%\JtR" /S /Q
)
IF /I EXIST "%ProgramData%\zr-offline.txt" (
	>nul 2>&1 DEL "%ProgramData%\zr-offline.txt" /F /Q
)
IF /I EXIST "%ProgramData%\7zExtra.7z" (
	>nul 2>&1 DEL "%ProgramData%\7zExtra.7z" /F /Q
)
IF /I EXIST "%ProgramData%\7zr.exe" (
	>nul 2>&1 DEL "%ProgramData%\7zr.exe" /F /Q
)
IF /I EXIST "%ProgramData%\perlportable.zip" (
	>nul 2>&1 DEL "%ProgramData%\perlportable.zip" /F /Q
)
IF /I EXIST "%ProgramData%\winX64_1_JtR.7z" (
	>nul 2>&1 DEL "%ProgramData%\winX64_1_JtR.7z" /F /Q
)
IF /I EXIST "%ProgramData%\zipripper.png" (
	>nul 2>&1 DEL "%ProgramData%\zipripper.png" /F /Q
)
IF /I EXIST "%ProgramData%\launcher.ZipRipper" (
	>nul 2>&1 DEL "%ProgramData%\launcher.ZipRipper" /F /Q
)
IF /I EXIST "%ProgramData%\ztmp\*" (
	>nul 2>&1 RD "%ProgramData%\ztmp" /S /Q
)
IF "%1"=="" (
	>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F
	(GOTO) 2>nul&DEL "%~f0"/F /Q>nul&EXIT
)
EXIT /b

:BUILD
IF EXIST "%ProgramData%\ztmp\*" (
	>nul 2>&1 RD "%ProgramData%\ztmp" /S /Q
)
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
POWERSHELL -nop -c "Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration;[xml]$xaml='<Window xmlns="^""http://schemas.microsoft.com/winfx/2006/xaml/presentation"^"" xmlns:x="^""http://schemas.microsoft.com/winfx/2006/xaml"^"" Title="^""Building [zr-offline.txt]"^"" Height="^""75"^"" Width="^""210"^"" WindowStartupLocation="^""CenterScreen"^"" WindowStyle="^""None"^"" Topmost="^""True"^"" Background="^""#333333"^"" AllowsTransparency="^""True"^""><Canvas><TextBlock Name="^""Info"^"" Canvas.Top="^""3"^"" Text="^"" Initializing..."^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""28"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress"^"" Foreground="^""#FF0000"^""/><TextBlock Name="^""Info2"^"" Canvas.Top="^""38"^"" Text="^"" Getting Resources (Stage 1/2)"^"" Foreground="^""#eeeeee"^"" FontWeight="^""Bold"^""/><ProgressBar Canvas.Left="^""5"^"" Canvas.Top="^""63"^"" Width="^""200"^"" Height="^""3"^"" Name="^""Progress2"^"" Foreground="^""#FF0000"^""/></Canvas><Window.TaskbarItemInfo><TaskbarItemInfo/></Window.TaskbarItemInfo></Window>';$reader=(New-Object System.Xml.XmlNodeReader $xaml);$form=[Windows.Markup.XamlReader]::Load($reader);$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage;$bitmap='%ProgramData%\zipripper.png';$form.Icon=$bitmap;$form.TaskbarItemInfo.Overlay=$bitmap;$form.TaskbarItemInfo.Description=$form.Title;$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid});$progressBar=$form.FindName("^""Progress"^"");$progressTotal=$form.FindName("^""Progress2"^"");$info=$form.FindName("^""Info"^"");$info2=$form.FindName("^""Info2"^"");function Update-Gui (){$form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})};function Build () {$info.Text=' Downloading 7zr Standalone';Update-Gui;downloadFile 'https://www.7-zip.org/a/7zr.exe' '%ProgramData%\ztmp\101';$info.Text=' Downloading 7za Console';Update-Gui;downloadFile 'https://www.7-zip.org/a/7z2300-extra.7z' '%ProgramData%\ztmp\100';$info.Text=' Downloading JohnTheRipper';Update-Gui;downloadFile 'https://github.com/openwall/john-packages/releases/download/bleeding/winX64_1_JtR.7z' '%ProgramData%\ztmp\103';$info.Text=' Downloading Portable Perl';Update-Gui;downloadFile 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip' '%ProgramData%\ztmp\102';$progressBar.Value=0;$info.Text=' Merging resources'; $info2.Text=' Building zr-offline.txt (Stage 2/2)';$pass=1;Update-Gui;makecab.exe /F '%ProgramData%\ztmp\offline.config' /D Compress='OFF' /D CabinetNameTemplate='%ProgramData%\ztmp\zr-offline.txt'| out-string -stream | Select-String -Pattern "^""(\d{1,3})(?=[.]\d{1,2}%%)"^"" -AllMatches | ForEach-Object { $_.Matches.Value } | foreach {$progressBar.Value=$_;if($totalP2 -ge 6){$progressTotal.Value=$progressTotal.Value + 1;$totalP2=0};if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;$totalP2++};if($progressBar.Value -ge 100){$pass++};if($pass -eq 2){$info.Text="^"" Building data file"^"";if($progressBar.Value -eq 99){$pass++}};if($pass -eq 3){$info.Text="^"" Purging Cache"^""};if($progressBar.Value -ne $lastpercent2){$lastpercent2=$progressBar.Value;Update-Gui}};$progressBar.Value=100;$m=([IO.File]::ReadAllLines('%ProgramData%\launcher.ZipRipper')).Replace('"^""','');Move-Item -Path '%ProgramData%\ztmp\zr-offline.txt' -Destination "^""$m"^"" -Force;$progressTotal.Value=100;$info.Text="^"" Build Completed!"^"";Update-Gui;Sleep 3};function DownloadFile($url,$targetFile){$uri=New-Object "^""System.Uri"^"" "^""$url"^"";$request=[System.Net.HttpWebRequest]::Create($uri);$request.set_Timeout(15000);$response=$request.GetResponse();$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024);$responseStream=$response.GetResponseStream();$targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create;$buffer=new-object byte[] 10KB;$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$count;while ($count -gt 0){$targetStream.Write($buffer, 0, $count);$count=$responseStream.Read($buffer,0,$buffer.length);$downloadedBytes=$downloadedBytes + $count;$roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024))/$totalLength)*100);$progressBar.Value=$roundedPercent;if($totalP -ge 7){$progressTotal.Value++;$totalP=0};if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;$totalP++;Update-Gui}};$targetStream.Flush();$targetStream.Close();$targetStream.Dispose();$responseStream.Dispose()};$form.Add_ContentRendered({Build;$form.Close()});$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)">nul
POPD
>nul 2>&1 RD "%ProgramData%\ztmp" /S /Q
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup('Re-launch ZipRipper in Offline Mode?',0,'Build Complete.',32+4)"`) DO (
	SET %1=%%#
)
EXIT /b

:CPUMODESPLIT
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$Msg+='Would you like to split the wordlist?';$Msg+="^""`n"^"";$Msg+="^""`n"^"";$Msg+='WARNING - There may be up to a 60 second delay from when a password is found, before the remaining lists are halted.';$Msg+="^""`n"^"";$Msg+="^""`n"^"";$Msg+='To split the wordlist click YES';$Msg+="^""`n"^"";$Msg+="^""`n"^"";$Msg+='To run ZipRipper in default mode click NO (If this is your first attempt you should click NO)';$^=New-Object -ComObject Wscript.Shell;$^.Popup($Msg,0,'CPU Mode Detected',32+4)"`) DO (
	IF %%# EQU 6 (
		FOR /F "tokens=*" %%# in ('wmic cpu get NumberOfCores /value ^| find "="') do (
			FOR /F "tokens=2 delims==" %%# in ("%%#") do (
				SET AVAILABLECORES=%%#			)
		)
	)
)
IF DEFINED AVAILABLECORES (
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET "FLAG=--fork=!AVAILABLECORES!"
	ENDLOCAL
)
EXIT /b

:CHECKGPU
FOR /F "usebackq skip=1 tokens=2,3" %%# IN (`WMIC path Win32_VideoController get Name ^| findstr "."`) DO (
	IF /I "%%#"=="GeForce" (
		IF /I NOT EXIST "%WinDir%\System32\OpenCL.dll" (
			IF /I EXIST "%WinDir%\System32\DriverStore\FileRepository\nvamig.inf_amd64_72a8482547fd21bc\OpenCL64.dll" (
				>nul 2>&1 COPY /Y "%WinDir%\System32\DriverStore\FileRepository\nvamig.inf_amd64_72a8482547fd21bc\OpenCL64.dll" "%WinDir%\System32\OpenCL.dll"
				SET GPU=1
			) ELSE (
				SET GPU=0
			)
		) ELSE (
			SET GPU=1
		)
	)
	IF /I "%%#"=="RTX" (
		IF /I NOT EXIST "%WinDir%\System32\OpenCL.dll" (
			SET GPU=0
		) ELSE (
			SET GPU=1
		)
	)
	IF /I "%%#"=="A800" (
		IF /I NOT EXIST "%WinDir%\System32\OpenCL.dll" (
			SET GPU=0
		) ELSE (
			SET GPU=1
		)
	)
	IF /I "%%#"=="T1000" (
		IF /I NOT EXIST "%WinDir%\System32\OpenCL.dll" (
			SET GPU=0
		) ELSE (
			SET GPU=1
		)
	)
	IF /I "%%#"=="Quadro" (
		IF /I NOT EXIST "%WinDir%\System32\OpenCL.dll" (
			IF /I EXIST "%WinDir%\System32\DriverStore\FileRepository\nvamig.inf_amd64_72a8482547fd21bc\OpenCL64.dll" (
				>nul 2>&1 COPY /Y "%WinDir%\System32\DriverStore\FileRepository\nvamig.inf_amd64_72a8482547fd21bc\OpenCL64.dll" "%WinDir%\System32\OpenCL.dll"
				SET GPU=1
			) ELSE (
				SET GPU=0
			)
		) ELSE (
			SET GPU=1
		)
	)
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF NOT !GPU!==1 (
		ENDLOCAL
		IF /I NOT EXIST "%ProgramData%\ignore.Radeon" (
			IF /I "%%#"=="Radeon" (
				IF /I NOT EXIST "%WinDir%\System32\amdocl64.dll" (
					CALL :FIXRADEON
				) ELSE (
					REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors" /v "%WinDir%\System32\amdocl64.dll" >nul 2>&1
					IF %ERRORLEVEL% NEQ 0 (
						CALL :FIXRADEON
					)
				)
				IF /I "%%# %%$"=="Radeon RX" (
					IF /I NOT EXIST "%WinDir%\System32\amdocl64.dll" (
						SET GPU=0
					) ELSE (
						SET GPU=2
					)
				)
				IF /I "%%# %%$"=="Radeon Pro" (
					IF /I NOT EXIST "%WinDir%\System32\amdocl64.dll" (
						SET GPU=0
					) ELSE (
						SET GPU=2
					)
				)
			)
		)
	) ELSE (
		ENDLOCAL
	)
)
EXIT /b

:SETTERMINAL
SET "LEGACY={B23D10C0-E52E-411E-9D5B-C09FDF709C7D}"
SET "LETWIN={00000000-0000-0000-0000-000000000000}"
SET "TERMINAL={2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
SET "TERMINAL2={E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"
POWERSHELL -nop -c "Get-WmiObject -Class Win32_OperatingSystem | Select -ExpandProperty Caption | Find 'Windows 11'">nul
IF ERRORLEVEL 0 (
	SET isEleven=1
	>nul 2>&1 REG QUERY "HKCU\Console\%%%%Startup" /v DelegationConsole
	IF ERRORLEVEL 1 (
		REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%LETWIN%" /f>nul
		REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%LETWIN%" /f>nul
	)
	FOR /F "usebackq tokens=3" %%# IN (`REG QUERY "HKCU\Console\%%%%Startup" /v DelegationConsole 2^>nul`) DO (
		IF NOT "%%#"=="%LEGACY%" (
			SET "DEFAULTCONSOLE=%%#"
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%LEGACY%" /f>nul
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%LEGACY%" /f>nul
		)
	)
)
FOR /F "usebackq tokens=3" %%# IN (`REG QUERY "HKCU\Console" /v ForceV2 2^>nul`) DO (
	IF NOT "%%#"=="0x1" (
		SET LEGACYTERM=0
		REG ADD "HKCU\Console" /v ForceV2 /t REG_DWORD /d 1 /f>nul
	) ELSE (
		SET LEGACYTERM=1
	)
)
EXIT /b

:RESTORETERMINAL
IF "%isEleven%"=="1" (
	IF DEFINED DEFAULTCONSOLE (
		IF "%DEFAULTCONSOLE%"=="%TERMINAL%" (
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%TERMINAL%" /f>nul
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%TERMINAL2%" /f>nul
		) ELSE (
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%DEFAULTCONSOLE%" /f>nul
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%DEFAULTCONSOLE%" /f>nul
		)
	)
)
IF "%LEGACYTERM%"=="0" (
	REG ADD "HKCU\Console" /v ForceV2 /t REG_DWORD /d 0 /f>nul
)
EXIT /b

:SAVELOCATION
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "[Environment]::GetFolderPath('Desktop')"`) DO (
	SET "%1=%%#"
)
EXIT /b

:SAVEFILE
IF EXIST "%UserDesktop%\ZipRipper-Passwords.txt" (
	SET R=0
	CALL :RENAMEOLD
)
(
	ECHO ^[ZIP-Ripper^] - FOUND PASSWORDS
	ECHO  %DATE% + %TIME%
	ECHO ==============================
	ECHO/
)>"%UserDesktop%\ZipRipper-Passwords.txt"
SETLOCAL ENABLEDELAYEDEXPANSION
IF "!ZIP2!"=="1" (
	ENDLOCAL
	CALL :MULTI
) ELSE (
	ENDLOCAL
	CALL :SINGLE %1
)
(
	ECHO/
	ECHO ==============================
)>>"%UserDesktop%\ZipRipper-Passwords.txt"
EXIT /b

:FIXRADEON
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "$^=New-Object -ComObject Wscript.Shell;$^.Popup('Radeon series GPU detected, but OpenCL dependencies are missing.. Would you like to perform a one-time download from AMD to enable OpenCL support on your system? (~13mb)',0,'Enable AMD OpenCL Support?',0x1)"`) DO (
	IF %%# EQU 1 (
		CALL :SINGLEDOWNLOAD "https://download.amd.com/dir/bin/amdocl64.dll/64CB5B3Ed36000/amdocl64.dll" "%WinDir%\System32\amdocl64.dll" "Adding AMD OpenCL support..."
		>nul 2>&1 REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors" /v "%WinDir%\System32\amdocl64.dll" /t REG_DWORD /d 0 /f
	) ELSE (
		CD.>"%ProgramData%\ignore.Radeon"
	)
)
EXIT /b