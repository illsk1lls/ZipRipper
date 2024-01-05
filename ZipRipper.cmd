@ECHO OFF
REM Check architecture - x64 only
IF NOT "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
		ECHO FOR USE WITH x64 SYSTEMS ONLY
		ECHO/
		PAUSE
		EXIT /b
	) ELSE (
		ECHO UNABLE TO LAUNCH IN x86 MODE
		ECHO/
		PAUSE
		EXIT /b
	)
)
REM Supported extensions and dependencies, declare init vars
SET "NATIVE=ZIP,RAR"
SET "PERL=7z,PDF"
SET GPU=0
SET ALLOWSTART=0
TITLE Please Wait...
CALL :CHECKCOMPAT
REM Check if more than one file was dropped
IF NOT "%~2"=="" (
	ECHO Multiple files are not supported, Please drop one file at a time.
	ECHO/
	PAUSE
	EXIT /b
)
IF "%~1"=="" (
	REM If no file was dropped via GUI, use file picker and relaunch, causes extra relaunch to assign %1
	CALL :GETFILE FILENAME
	SET "SELF=%~dpnx0"
	SETLOCAL ENABLEDELAYEDEXPANSION
	IF "!FILENAME!"=="" (
	ECHO ERROR: No file was selected.
	ECHO/
	ECHO Drop a password protected %NATIVE%,%PERL% file onto the script, or relaunch
	ECHO the script and select a file with the GUI
	ECHO/
	PAUSE
	EXIT /b
	)
	START "" "!SELF:"=!" !FILENAME!>nul
	ENDLOCAL
	EXIT /b
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
REM If drop is unsupported, display supported extensions and exit
IF NOT "%ALLOWSTART%"=="1" (
	ECHO Unsupported file extension. Supported extensions are: %NATIVE%,%PERL%
	ECHO/
	PAUSE
	EXIT /b
)
SET "FILETYPE=%~x1"
REM Request Admin if not, Generates UAC prompt
>nul 2>&1 REG ADD HKCU\Software\classes\.ZipRipper\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=%%2\"& CALL \"%%2\" %%3"&SET "_= %*"
>nul 2>&1 FLTMC|| IF NOT "%f0%"=="%~f0" (cd.>"%ProgramData%\elevate.ZipRipper"&START "%~n0" /high "%ProgramData%\elevate.ZipRipper" "%~f0" "%_:"=""%"&EXIT)
>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F &>nul 2>&1 del %ProgramData%\elevate.ZipRipper /F /Q
REM Copy offline resources to %ProgramData% if present
IF EXIST "%~dp0zr-offline.txt" >nul 2>&1 COPY /Y "%~dp0zr-offline.txt" "%ProgramData%"
REM Only allow one instance at a time
SET "TitleName=^[ZIP-Ripper^]  -  ^[CPU Mode^]  -  ^[OpenCL DISABLED^]"
IF "%GPU%"=="1" SET TitleName=%TitleName:^[CPU Mode^]  -  ^[OpenCL DISABLED^]=^[CPU/GPU Mode^]  -  ^[OpenCL ENABLED^]%
TASKLIST /V /NH /FI "imagename eq cmd.exe"|FIND /I /C "%TitleName%">nul
IF NOT %errorlevel%==1 (ECHO ERROR:&ECHO ZIP-Ripper is already running!) |MSG *&EXIT
TITLE %TitleName%
REM Center CMD window with powershell, doesnt work with new terminal
>nul 2>&1 POWERSHELL -nop -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport(\"user32.dll\")]public static extern void SetProcessDPIAware();[DllImport(\"shcore.dll\")]public static extern void SetProcessDpiAwareness(int value);[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern void GetWindowRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport(\"user32.dll\")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport(\"user32.dll\")]public static extern int SetWindowPos(IntPtr hwnd, IntPtr hwndAfterZ, int x, int y, int w, int h, int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try {$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)} catch {$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7] - $moninf[5];$monheight=$moninf[8] - $moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2] - $wrect[0];$winheight=$wrect[3] - $wrect[1];$x=[int][math]::Round($moninf[5] + $monwidth / 2 - $winwidth / 2);$y=[int][math]::Round($moninf[6] + $monheight / 2 - $winheight / 2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, 0, 0, $SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
REM Test internet connection, if FALSE exit if zr-offline.txt is not present
PING -n 1 "google.com" | FINDSTR /r /c:"[0-9] *ms">nul
IF NOT %errorlevel%==0 (
	IF NOT EXIST "%ProgramData%\zr-offline.txt" (
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
		EXIT /b
	)
)
IF EXIST "%ProgramData%\JtR" >nul 2>&1 RD "%ProgramData%\JtR" /S /Q
REM Remove old incomplete BITS downloads from previous interrupted sessions, if present
>nul 2>&1 ATTRIB -h "%ProgramData%\BIT*.tmp"
IF EXIST "%ProgramData%\BIT*.tmp" >nul 2>&1 DEL "%ProgramData%\BIT*.tmp" /F /Q
CALL :GETJTRREADY
REM Input JtR settings
PUSHD "%ProgramData%\JtR\run"
REN john.conf john.defaultconf
POWERSHELL -nop -c "$^=gc john.defaultconf|%%{$_.Replace('SingleMaxBufferAvailMem = N','SingleMaxBufferAvailMem = Y').Replace('MaxKPCWarnings = 10','MaxKPCWarnings = 0')}|sc john.conf">nul 2>&1
CLS
SET "FLAG="
REM If filesize is large hash will take a while
IF %~z1 GEQ 200000000 (
	ECHO Creating password hash - This can take a few minutes on large files...
) ELSE (
	ECHO Creating password hash...
)
SET ZIP2=0
REM Get pwhash
CALL :HASH%FILETYPE% %1
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
REM Cleanup temp files and exit
RD "%ProgramData%\JtR" /S /Q>nul
EXIT /b

:ELEVATE
EXIT /b

:GETJTRREADY
CLS
REM Check if zr-offline.txt is present, if not, run in online mode
IF NOT EXIST "%ProgramData%\zr-offline.txt" (
	ECHO Retrieving tools...
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '%ProgramData%\7zr.exe'";"Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '%ProgramData%\7zExtra.7z'"
	CLS
	IF "%ISPERL%"=="1" (
		REM Download JtR, and perl portable
		ECHO Retrieving required dependencies, please wait...
POWERSHELL -nop -c "Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%ProgramData%\winX64_1_JtR.7z'";"Start-BitsTransfer -Priority Foreground -Source https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip -Destination '%ProgramData%\perlportable.zip'"
	) ELSE (
		REM Download JtR only
		ECHO Retrieving required dependencies...
POWERSHELL -nop -c "Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%ProgramData%\winX64_1_JtR.7z'"
	)
) ELSE (
	REM Offline mode, use local file
	ECHO Offline mode enabled, preparing resources...
	REN "%ProgramData%\zr-offline.txt" .resources.exe
	"%ProgramData%\.resources" -y -pDependencies">nul
	>nul 2>&1 DEL "%ProgramData%\.resources.exe" /F /Q
)
REM Extract JtR
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\winX64_1_JtR.7z" -o"%ProgramData%\"
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\7zExtra.7z" -o"%ProgramData%\JtR\"
REM Extract perl portable if needed
IF "%ISPERL%"=="1" (
	CLS
	ECHO Extracting required dependencies, this will take a moment...
	"%ProgramData%\JtR\7za.exe" x -y "%ProgramData%\perlportable.zip" -o"%ProgramData%\JtR\run">nul
	>nul 2>&1 DEL "%ProgramData%\perlportable.zip" /F /Q
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
FOR /F "usebackq tokens=* delims=" %%# IN (`POWERSHELL -nop -c "Add-Type -AssemblyName System.Windows.Forms;$^=New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory='%~dp0';Title='Select a password protected ZIP, RAR, 7z or PDF...';Filter='All Supported (*.zip;*.rar;*.7z;*.pdf)|*.zip;*.rar;*.7z;*.pdf|ZIP (*.zip)|*.zip|RAR (*.rar)|*.rar|7-Zip (*.7z)|*.7z|PDF (*.pdf)|*.pdf'};$null=$^.ShowDialog();If($^.Filename -match ' '){$Quoted='"^""' + $^^.Filename + '"^""';$Quoted}ELSE{$^.Filename}"`) DO SET %1=%%#
EXIT /b