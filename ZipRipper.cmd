@ECHO OFF&IF NOT "%PROCESSOR_ARCHITECTURE%"=="AMD64" ECHO FOR USE WITH x64 SYSTEMS ONLY&ECHO.&PAUSE&EXIT
SET "NATIVE=ZIP,RAR"&SET "PERL=7z,PDF"&TITLE Please Wait...&SET/A GPU=0&SET/A GO=0&CALL :CHECKCOMPAT
IF NOT "%~2"=="" ECHO Multiple files are not supported, Please drop one file at a time.&ECHO.&PAUSE&EXIT
IF "%~1"=="" (ECHO Drop a password protected %NATIVE%,%PERL% file onto the script to begin...&ECHO.&PAUSE&EXIT) ELSE ((FOR %%# IN (%NATIVE%) DO IF /I "%~x1"==".%%#" SET/A GO=1&SET/A ISPERL=0)&(FOR %%# IN (%PERL%) DO IF /I "%~x1"==".%%#" SET/A GO=1&SET/A ISPERL=1))
(IF %GO% NEQ 1 ECHO Unsupported file extension. Supported extensions are: %NATIVE%,%PERL%&ECHO.&PAUSE&EXIT)&SET "FILETYPE=%~x1"
>nul 2>&1 REG ADD HKCU\Software\classes\.ZipRipper\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=%%2\"& CALL \"%%2\" %%3"&SET "_= %*"
>nul 2>&1 FLTMC|| IF "%f0%" neq "%~f0" (cd.>"%ProgramData%\elevate.ZipRipper"&START "%~n0" /high "%ProgramData%\elevate.ZipRipper" "%~f0" "%_:"=""%"&EXIT/b)
>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F &>nul 2>&1 del %ProgramData%\elevate.ZipRipper /F /Q
CD /D %~dp0&IF NOT "%~f0" EQU "%ProgramData%\%~nx0" >nul 2>&1 COPY /Y "%~f0" "%ProgramData%"&START "" ""%ProgramData%\%~nx0"" "%_%">nul&EXIT/b
SET "TitleName=^[ZipRipper^]  -  ^[CPU Mode^]  ^[OpenCL DISABLED^]"
IF %GPU% EQU 1 SET TitleName=%TitleName:^[CPU Mode^]  ^[OpenCL DISABLED^]=^[CPU/GPU Mode^]  ^[OpenCL ENABLED^]%
TASKLIST /V /NH /FI "imagename eq cmd.exe"|FIND /I /C "%TitleName%">nul
IF NOT %errorlevel%==1 (ECHO ERROR:&ECHO ZipRipper is already running!) |MSG *&EXIT
TITLE %TitleName%
::Center CMD window
>nul 2>&1 POWERSHELL -nop -c "$w=Add-Type -Name WAPI -PassThru -MemberDefinition '[DllImport(\"user32.dll\")]public static extern void SetProcessDPIAware();[DllImport(\"shcore.dll\")]public static extern void SetProcessDpiAwareness(int value);[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern void GetWindowRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetClientRect(IntPtr hwnd, int[] rect);[DllImport(\"user32.dll\")]public static extern void GetMonitorInfoW(IntPtr hMonitor, int[] lpmi);[DllImport(\"user32.dll\")]public static extern IntPtr MonitorFromWindow(IntPtr hwnd, int dwFlags);[DllImport(\"user32.dll\")]public static extern int SetWindowPos(IntPtr hwnd, IntPtr hwndAfterZ, int x, int y, int w, int h, int flags);';$PROCESS_PER_MONITOR_DPI_AWARE=2;try {$w::SetProcessDpiAwareness($PROCESS_PER_MONITOR_DPI_AWARE)} catch {$w::SetProcessDPIAware()}$hwnd=$w::GetConsoleWindow();$moninf=[int[]]::new(10);$moninf[0]=40;$MONITOR_DEFAULTTONEAREST=2;$w::GetMonitorInfoW($w::MonitorFromWindow($hwnd, $MONITOR_DEFAULTTONEAREST), $moninf);$monwidth=$moninf[7] - $moninf[5];$monheight=$moninf[8] - $moninf[6];$wrect=[int[]]::new(4);$w::GetWindowRect($hwnd, $wrect);$winwidth=$wrect[2] - $wrect[0];$winheight=$wrect[3] - $wrect[1];$x=[int][math]::Round($moninf[5] + $monwidth / 2 - $winwidth / 2);$y=[int][math]::Round($moninf[6] + $monheight / 2 - $winheight / 2);$SWP_NOSIZE=0x0001;$SWP_NOZORDER=0x0004;exit [int]($w::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, 0, 0, $SWP_NOSIZE -bOr $SWP_NOZORDER) -eq 0)"
PING -n 1 "google.com" | FINDSTR /r /c:"[0-9] *ms">nul
IF NOT %errorlevel%==0 ECHO.&ECHO Internet connection not detected, the latest JtR is needed to proceed...&ECHO.&PAUSE&(GOTO) 2>nul&del "%~f0" /F /Q>nul&EXIT
IF EXIST "%ProgramData%\JtR" >nul 2>&1 RD "%ProgramData%\JtR" /S /Q
CALL :GETJTRREADY
PUSHD "%ProgramData%\JtR\run"
CLS&SET "FLAG="&IF %~z1 GEQ 200000000 (ECHO Creating Password Hash - This can take a few minutes on large files...) ELSE (ECHO Creating Password Hash...)
CALL :HASH%FILETYPE% %1
CLS&ECHO Running JohnTheRipper...&ECHO.
SETLOCAL ENABLEDELAYEDEXPANSION&john pwhash !FLAG!&ENDLOCAL
ECHO.&PAUSE
POPD&RD "%ProgramData%\JtR" /S /Q>nul&(GOTO) 2>nul&DEL "%~f0"/F /Q>nul&EXIT
:GETJTRREADY
CLS&ECHO Getting Decompression Tools...
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '%~dp07zr.exe'"; "Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '%~dp07zExtra.7z'"
IF %ISPERL% EQU 1 (CLS&ECHO Getting Decryption Tools, Be patient...&SET "EXTRA=;Start-BitsTransfer -Priority Foreground -Source https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip -Destination '%~dp0\perlportable.zip'") ELSE (CLS&ECHO Getting Decryption Tools...&SET "EXTRA=")
POWERSHELL -nop -c "Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%~dp0winX64_1_JtR.7z'%EXTRA%"
>nul 2>&1 "%~dp07zr.exe" x -y "%~dp0winX64_1_JtR.7z"&>nul 2>&1 "%~dp07zr.exe" x -y "%~dp07zExtra.7z" -o"%~dp0JtR\"
IF %ISPERL% EQU 1  CLS&ECHO Extracting Decryption Dependencies, this will take a moment...&"%~dp0JtR\7za.exe" x -y "%~dp0perlportable.zip" -o"%~dp0JtR\run">nul&>nul 2>&1 DEL "%~dp0perlportable.zip" /F /Q
>nul 2>&1 DEL "%~dp0winX64_1_JtR.7z" /F /Q&>nul 2>&1 DEL "%~dp07zr.exe" /F /Q&>nul 2>&1 DEL "%~dp07zExtra.7z" /F /Q
IF %GPU% EQU 1 >nul 2>&1 COPY /Y "%WinDir%\System32\OpenCL.dll" "%ProgramData%\JtR\run\cygOpenCL-1.dll"
EXIT/b
:CHECKCOMPAT
FOR /F "usebackq skip=2 tokens=3,4" %%# IN (`REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul`) DO (IF "%%# %%$"=="Windows 7" ECHO.&ECHO Windows 7 detected.&ECHO.&ECHO SYSTEM NOT SUPPORTED&ECHO.&PAUSE&EXIT)
FOR /F "usebackq skip=1 tokens=2,3" %%# IN (`WMIC path Win32_VideoController get Name ^| findstr "."`) DO (IF /I "%%#"=="GeForce" SET/A GPU=1)&(IF /I "%%#"=="Quadro" SET/A GPU=1)&(IF /I "%%# %%$"=="Radeon RX" SET/A GPU=1)&(IF /I "%%# %%$"=="Radeon Pro" SET/A GPU=1)
IF NOT EXIST "%WinDir%\System32\OpenCL.dll" SET/A GPU=0
EXIT/b
:HASH.ZIP
zip2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
IF %GPU% EQU 1 FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO IF "%%#"=="zip2" SET "FLAG=--format=ZIP-opencl"
EXIT/b
:HASH.RAR
rar2john "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
IF %GPU% EQU 1 FOR /F "tokens=2 delims=$" %%# IN (pwhash) DO (IF "%%#"=="rar" SET "FLAG=--format=rar-opencl")&(IF "%%#"=="rar5" SET "FLAG=--format=RAR5-opencl")
EXIT/b
:HASH.7z
CALL portableshell.bat 7z2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
IF %GPU% EQU 1 SET "FLAG=--format=7z-opencl"
EXIT/b
:HASH.PDF
CALL portableshell.bat pdf2john.pl "%~1">"%ProgramData%\JtR\run\pwhash" 2>nul
POWERSHELL -nop -c "$f=gc pwhash; $m=[regex]::Matches($f,'^(.+\/)(?i)(.*\.pdf)(.+$)') | %% {$_.Groups[2].Value+$_.Groups[3].Value} | sc pwhash"
EXIT/b