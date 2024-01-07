@ECHO OFF
IF NOT "%~2"=="" (
	ECHO Multiple files are not supported. Double-click the script and use the GUI to select a file...
	ECHO/
	PAUSE
	EXIT
)
REM Test internet connection, if FALSE exit if zr-offline.txt is not present
SET OFFLINE=1
IF NOT EXIST "%~dp0zr-offline.txt" (
SET OFFLINE=0
PING -n 1 "google.com" | FINDSTR /r /c:"[0-9] *ms">nul
IF NOT %errorlevel%==0 (
		ECHO/
		ECHO Internet connection not detected...
		ECHO/
		ECHO ^[zr-offline.txt^] must be in the same folder as ZIP-Ripper for offline mode.
		ECHO/
		ECHO It can be downloaded using the below address:
		ECHO/
		ECHO https://github.com/illsk1lls/ZipRipper/raw/main/.resources/zr-offline.txt?download=
		ECHO/
		PAUSE
		REM GOTO nowhere, self-delete %ProgramData% copy, and exit
		EXIT
	)
)
SET _= %*
REM Request Admin if not, Generates UAC prompt
CALL :ELEVATE %_%
IF NOT "%~f0"=="%ProgramData%\%~nx0" (
	>nul 2>&1 COPY /Y "%~f0" "%ProgramData%"
	IF EXIST "%~dp0zr-offline.txt" (
	>nul 2>&1 COPY /Y "%~dp0zr-offline.txt" "%ProgramData%"
	) ELSE (
	>nul 2>&1 DEL "%ProgramData%\zr-offline.txt" /F /Q
	)
	START /MIN "LoadScreen" ""%ProgramData%\%~nx0"" "%_:"=""%">nul
	EXIT /b
)
REM Check architecture - x64 only
IF NOT "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
		ECHO FOR USE WITH x64 SYSTEMS ONLY
		ECHO/
		PAUSE
		REM GOTO nowhere, self-delete %ProgramData% copy, and exit
		CALL :CLEANEXIT
	) ELSE (
		ECHO UNABLE TO LAUNCH IN x86 MODE
		ECHO/
		PAUSE
		REM GOTO nowhere, self-delete %ProgramData% copy, and exit
		CALL :CLEANEXIT
	)
)
REM Supported extensions and dependencies, declare init vars
SET "NATIVE=ZIP,RAR"
SET "PERL=7z,PDF"
SET GPU=0
SET ALLOWSTART=0
TITLE Please Wait...
CALL :CHECKCOMPAT
REM Cleanup previous sessions
IF EXIST "%ProgramData%\JtR" >nul 2>&1 RD "%ProgramData%\JtR" /S /Q
>nul 2>&1 ATTRIB -h "%ProgramData%\BIT*.tmp"
IF EXIST "%ProgramData%\BIT*.tmp" >nul 2>&1 DEL "%ProgramData%\BIT*.tmp" /F /Q
REM Center CMD window with powershell, doesnt work with new terminal
>nul 2>&1 POWERSHELL -nop -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport(\"user32.dll\")]public static extern void SetProcessDPIAware();[DllImport(\"shcore.dll\")]public static extern void SetProcessDpiAwareness(int value);[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern void GetWindowRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport(\"user32.dll\")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport(\"user32.dll\")]public static extern int SetWindowPos(IntPtr hwnd, IntPtr hwndAfterZ, int x, int y, int w, int h, int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try {$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)} catch {$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7] - $moninf[5];$monheight=$moninf[8] - $moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2] - $wrect[0];$winheight=$wrect[3] - $wrect[1];$x=[int][math]::Round($moninf[5] + $monwidth / 2 - $winwidth / 2);$y=[int][math]::Round($moninf[6] + $monheight / 2 - $winheight / 2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, 0, 0, $SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
REM Check if zr-offline.txt is present, if not run in online mode later
IF "%OFFLINE%"=="1" CALL :OFFLINEMODE
IF "%~1"=="" (
	REM Show splash screen
	CALL :SPLASHSCREEN
	REM Use GUI to select file
	CALL :GETFILE FILENAME
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF NOT EXIST !FILENAME! (
	EXIT
	)
	CALL START "" %~f0 !FILENAME!
	ENDLOCAL
	EXIT
) ELSE (
	REM Flag supported filetypes to allow start and dependencies
	FOR %%# IN (%NATIVE%) DO IF /I "%~x1"==".%%#" (
		SET ALLOWSTART=1
		SET ISPERL=0
	)
	FOR %%# IN (%PERL%) DO IF /I "%~x1"==".%%#" (
		SET ALLOWSTART=1
		SET ISPERL=1
	)
)
IF NOT "%ALLOWSTART%"=="1" (
	CALL :CLEANEXIT
)
SET "FILETYPE=%~x1"
REM Only allow one instance at a time
SET "TitleName=^[ZIP-Ripper^]  -  ^[CPU Mode^]  -  ^[OpenCL DISABLED^]"
IF "%GPU%"=="1" SET TitleName=%TitleName:^[CPU Mode^]  -  ^[OpenCL DISABLED^]=^[CPU/GPU Mode^]  -  ^[OpenCL ENABLED^]%
TASKLIST /V /NH /FI "imagename eq cmd.exe"|FIND /I /C "%TitleName%">nul
IF NOT %errorlevel%==1 (ECHO ERROR:&ECHO ZIP-Ripper is already running!) |MSG *&EXIT
TITLE %TitleName%
IF "%OFFLINE%"=="0" CALL :ONLINEMODE
CALL :GETJTRREADY
ECHO Done&ECHO/
REM Input JtR settings
PUSHD "%ProgramData%\JtR\run"
REN john.conf john.defaultconf
POWERSHELL -nop -c "$^=gc john.defaultconf|%%{$_.Replace('SingleMaxBufferAvailMem = N','SingleMaxBufferAvailMem = Y').Replace('MaxKPCWarnings = 10','MaxKPCWarnings = 0')}|sc john.conf">nul 2>&1
SET "FLAG="
REM If filesize is large hash will take a while
IF %~z1 GEQ 200000000 (
	<NUL set /p=Creating password hash - This can take a few minutes on large files...
) ELSE (
	<NUL set /p=Creating password hash...
)
SET ZIP2=0
REM Get pwhash
CALL :HASH%FILETYPE% %1
ECHO Done
ECHO/
CLS
ECHO Running JohnTheRipper...
ECHO/
REM Start JtR
SETLOCAL ENABLEDELAYEDEXPANSION
john "%ProgramData%\JtR\run\pwhash" !FLAG!
ENDLOCAL
REM Check for found passwords
CALL :GETSIZE "%ProgramData%\JtR\run\john.pot" POTSIZE
REM Build password list if found
SETLOCAL ENABLEDELAYEDEXPANSION
IF !POTSIZE! GEQ 1 (
	ENDLOCAL
	SET FOUND=1
	CALL :SAVEFILE %1
	ECHO/
	ECHO Passwords saved to: "%UserProfile%\Desktop\ZipRipper-Passwords.txt"
) ELSE (
	ENDLOCAL
	SET FOUND=0
	ECHO/
	ECHO Password not found :^(
	
)
CALL :GETSIZE "%UserProfile%\Desktop\ZipRipper-Passwords.txt" PWSIZE
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT "%FOUND%"=="0" (
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
CALL :CLEANEXIT

:ELEVATE
>nul 2>&1 REG ADD HKCU\Software\classes\.ZipRipper\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=%%2\"& CALL \"%%2\" %%3"
>nul 2>&1 FLTMC|| IF NOT "%f0%"=="%~f0" (cd.>"%ProgramData%\elevate.ZipRipper"&START "%~n0" /min /high "%ProgramData%\elevate.ZipRipper" "%~f0" "%_:"=""%"&EXIT)
>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F &>nul 2>&1 del %ProgramData%\elevate.ZipRipper /F /Q
EXIT /b

:ONLINEMODE
<NUL set /p=Retrieving tools
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '%ProgramData%\7zr.exe'";"Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '%ProgramData%\7zExtra.7z'"
IF "%ISPERL%"=="1" (
	REM Download JtR, and perl portable
	<NUL set /p=, Getting required dependencies, please wait...
POWERSHELL -nop -c "Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%ProgramData%\winX64_1_JtR.7z'";"Start-BitsTransfer -Priority Foreground -Source https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip -Destination '%ProgramData%\perlportable.zip'"
) ELSE (
	REM Download JtR only
	<NUL set /p=, Getting required dependencies...
POWERSHELL -nop -c "Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%ProgramData%\winX64_1_JtR.7z'"
)
ECHO Done
ECHO/
EXIT /b

:OFFLINEMODE
REM Offline mode, use local file
<NUL set /p=Offline mode enabled, preparing resources...
REN "%ProgramData%\zr-offline.txt" .resources.exe>nul
"%ProgramData%\.resources" -y -pDependencies -o"%ProgramData%">nul
REN "%ProgramData%\.resources.exe" zr-offline.txt>nul
ECHO Done&ECHO/
EXIT /b

:GETJTRREADY
REM Extract JtR
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\winX64_1_JtR.7z" -o"%ProgramData%\"
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\7zExtra.7z" -o"%ProgramData%\JtR\"
IF "%ISPERL%"=="1" (
	REM Extract perl portable if needed
	<NUL set /p=Extracting required dependencies, this will take a moment...
	"%ProgramData%\JtR\7za.exe" x -y "%ProgramData%\perlportable.zip" -o"%ProgramData%\JtR\run">nul
	IF EXIST "%ProgramData%\perlportable.zip" >nul 2>&1 DEL "%ProgramData%\perlportable.zip" /F /Q
) ELSE (
	<NUL set /p=Extracting required dependencies...
)
REM Cleanup temp files
>nul 2>&1 DEL "%ProgramData%\winX64_1_JtR.7z" /F /Q
>nul 2>&1 DEL "%ProgramData%\7zr.exe" /F /Q
>nul 2>&1 DEL "%ProgramData%\7zExtra.7z" /F /Q
REM Enable OpenCL
IF "%GPU%"=="1" >nul 2>&1 COPY /Y "%WinDir%\System32\OpenCL.dll" "%ProgramData%\JtR\run\cygOpenCL-1.dll"
EXIT /b

:CHECKCOMPAT
REM Check Windows version
FOR /F "usebackq skip=2 tokens=3,4" %%# IN (`REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul`) DO (
	IF "%%# %%$"=="Windows 7" (
		ECHO/
		ECHO Windows 7 detected.
		ECHO/
		ECHO SYSTEM NOT SUPPORTED
		ECHO/
		PAUSE
		EXIT /b
	)
)
REM Detect GPU lineup and OpenCL availability
FOR /F "usebackq skip=1 tokens=2,3" %%# IN (`WMIC path Win32_VideoController get Name ^| findstr "."`) DO (
	IF /I "%%#"=="GeForce" SET GPU=1
	IF /I "%%#"=="Quadro" SET GPU=1
	IF /I "%%# %%$"=="Radeon RX" SET GPU=1
	IF /I "%%# %%$"=="Radeon Pro" SET GPU=1
REM Check if OpenCL is available
	IF NOT EXIST "%WinDir%\System32\OpenCL.dll" SET GPU=0
)
EXIT /b

:HASH.ZIP
zip2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
IF "%GPU%"=="1" FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (
	IF "%%#"=="zip2" (
		SET "FLAG=--format=ZIP-opencl"
		SET ZIP2=1
	)
)
EXIT /b

:HASH.RAR
rar2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
IF "%GPU%"=="1" FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (
	IF "%%#"=="rar" SET "FLAG=--format=rar-opencl"
	IF "%%#"=="rar5" SET "FLAG=--format=RAR5-opencl"
)
EXIT /b

:HASH.7z
CALL portableshell.bat 7z2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
IF "%GPU%"=="1" SET "FLAG=--format=7z-opencl"
EXIT /b

:HASH.PDF
CALL portableshell.bat pdf2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
POWERSHELL -nop -c "$^=[regex]::Match((gc pwhash),'^(.+\/)(?i)(.*\.pdf)(.+$)');$^.Groups[2].value+$^.Groups[3].value|sc pwhash">nul 2>&1
EXIT /b

:GETSIZE
REM Delayed expansion required to retrieve return value
SET /A "%2=%~z1"
EXIT /b

:SINGLE
FOR /F "usebackq tokens=2 delims=:" %%# IN (john.pot) DO ECHO|(SET /p="%%# - [%~nx1]"&ECHO/)>>"%UserProfile%\Desktop\ZipRipper-Passwords.txt"
EXIT /b

:MULTI
REM Show multiple found passwords via hash matches between initial 'pwhash' and 'john.pot'
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
REM Increment filename if exist
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
ENDLOCAL
(
	TYPE "%UserProfile%\Desktop\ZipRipper-Passwords.txt"
	ECHO Save Location:
	ECHO "%UserProfile%\Desktop\ZipRipper-Passwords.txt"
) |MSG * /time:999999
EXIT /b

:DISPLAYINFOB
(
	ECHO ^[ZIP-Ripper^] - FOUND PASSWORDS
	ECHO  %DATE% + %TIME%
	ECHO ==============================
	ECHO/
	ECHO TOO MANY TO LIST
	ECHO/
	ECHO ==============================
	ECHO Save Location:
	ECHO "%UserProfile%\Desktop\ZipRipper-Passwords.txt"
) |MSG * /time:999999
EXIT /b

:GETFILE
REM Open file picker to select a file, Delayed expansion required to retrieve return value
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName System.Windows.Forms;$^=New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory='';Title='Select a password protected ZIP, RAR, 7z or PDF...';Filter='All Supported (*.zip;*.rar;*.7z;*.pdf)|*.zip;*.rar;*.7z;*.pdf|ZIP (*.zip)|*.zip|RAR (*.rar)|*.rar|7-Zip (*.7z)|*.7z|PDF (*.pdf)|*.pdf'};$null=$^.ShowDialog();If($^.Filename -match ' '){$Quoted='"^""' + $^^.Filename + '"^""';$Quoted}ELSE{$^.Filename}"`) DO SET %1=%%#
EXIT /b

:SPLASHSCREEN
SET "SPLASH=%ProgramData%\john.jpg"
IF "%OFFLINE%"=="0" POWERSHELL -nop -c "Invoke-WebRequest -Uri https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/john.jpg -o '%ProgramData%\john.jpg'"
POWERSHELL -nop -c "Add-Type -AssemblyName 'System.Windows.Forms';$img=[System.Drawing.Image]::Fromfile((get-item '%SPLASH:'=''%'));Function ClearAndClose(){$Timer.Stop();$Form.Close();$Form.Dispose();$Timer.Dispose()};Function Timer_Tick(){$Label.Text = "Loading...";--$Script:CountDown;if ($Script:CountDown -lt 0){ClearAndClose}};[System.Windows.Forms.Application]::EnableVisualStyles();$form=new-object Windows.Forms.Form;$form.Width=$img.Size.Width;$form.Height=$img.Size.Height;$pictureBox=new-object Windows.Forms.PictureBox;$pictureBox.Width=$img.Size.Width;$pictureBox.Height=$img.Size.Height;$pictureBox.Image=$img;$form.controls.add($pictureBox);$form.Add_Shown({$form.Activate()});$form.FormBorderStyle='None';$form.StartPosition='CenterScreen';$Timer=New-Object System.Windows.Forms.Timer;$Timer.Interval=1000;$Script:CountDown=3;$Timer.Add_Tick({Timer_Tick});$Timer.Start();$form.ShowDialog()">nul
>nul 2>&1 DEL "%SPLASH%" /F /Q
EXIT /b

:CLEANEXIT
REM Cleanup temp files
RD "%ProgramData%\JtR" /S /Q>nul
IF EXIST "%ProgramData%\zr-offline.txt" >nul 2>&1 DEL "%ProgramData%\zr-offline.txt" /F /Q
REM GOTO nowhere, self-delete %ProgramData% copy, and exit
(GOTO) 2>nul&DEL "%~f0"/F /Q>nul&EXIT