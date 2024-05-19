@echo off
cls
echo OpenCL Driver (ICD) Fix for AMD GPUs
echo By Patrick Trumpis (https://github.com/ptrumpis/OpenCL-AMD-GPU)
echo Inspired by https://stackoverflow.com/a/28407851
echo/
echo Updated 5/19/24 for Radeon RX/Pro GPUs on x64 systems by illsk1lls ;P
echo/

>nul 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\config\system" && (
    goto :run
) || (
    echo Execution stopped
    echo =================
    echo This script requires administrator rights.
    echo Please run it again as administrator.
    echo You can right-click the file and select 'Run as administrator'

    echo/
    pause
    exit /b 1
)
:run
SETLOCAL EnableDelayedExpansion

SET "ROOTKEY64=HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors"
SET "ROOTKEY32=HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Khronos\OpenCL\Vendors"

echo Currently installed OpenCL Client Drivers - 64bit
echo ==================================================
for /f "tokens=1,*" %%A in ('reg query "%ROOTKEY64%" 2^>^&1') do (
	if "%%A"=="ERROR:" (
	echo None
	) else (
	echo %%A | findstr /c:".dll"
	if /I "%%A"=="%WinDir%\System32\amdocl64.dll" SET x64Installed=1
	)
)
echo/

echo Currently installed OpenCL Client Drivers - 32bit
echo ==================================================
for /f "tokens=1,*" %%A in ('reg query "%ROOTKEY32%" 2^>^&1') do (
	if "%%A"=="ERROR:" (
	echo None
	) else (
	echo %%A | findstr /c:".dll"
	)
)
echo/

if !x64Installed! EQU 1 (
echo AMDx64 OpenCL dll already registered...
echo/
echo Proceed to verify the file and register any other existing AMD OpenCL dlls..
) else (
echo Ready to Auto-Install/Register amdocl64.dll and any other existing AMD OpenCL dlls...
)
echo/

:askUserFastScan
set "INPUT="
set /P "INPUT=Do you want to continue? (Y/N): "
if /I "!INPUT!" == "Y" (
    echo/
    echo/
    goto :scanFilesFast
) else if /I "!INPUT!" == "N" (
    goto :exit
) else (
    goto :askUserFastScan
)

:scanFilesFast
cls
echo Running AMD OpenCL Driver Auto Detection
echo ========================================
echo/

echo Scanning '%SYSTEMROOT%\system32' for 'amdocl*.dll' files, please wait...
echo/

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
if /i not exist "%WinDir%\System32\amdocl64.dll" call :addMissingFiles
)

cd /d "%SYSTEMROOT%\system32"
call :registerMissingClientDriver

:complete
echo/
echo Scan complete.
echo/
pause

:exit
exit /b 0

:registerMissingClientDriver
for /r %%f in (amdocl*.dll) do (
    set "FILE=%%~dpnxf"

    for %%A in (amdocl.dll amdocl12cl.dll amdocl12cl64.dll amdocl32.dll amdocl64.dll) do (
        if /I "%%~nxf"=="%%A" (
            echo Found: !FILE!
			echo/

            echo !FILE! | findstr /C:"64" >nul
            if !ERRORLEVEL! == 0 (
                set "ROOTKEY=!ROOTKEY64!"
            ) else (
                set "FILE_BIT=!FILE:~-7,-5!"
				
                if !FILE_BIT! == 64 (
                    set "ROOTKEY=!ROOTKEY64!"
                ) else (
                    set "ROOTKEY=!ROOTKEY32!"
                )
            )

            reg query "!ROOTKEY!" >nul 2>&1
            if !ERRORLEVEL! neq 0 (
                reg add "!ROOTKEY!" /f >nul 2>&1
                echo Added Key: !ROOTKEY!
            )

            reg query "!ROOTKEY!" /v "!FILE!" >nul 2>&1

            if !ERRORLEVEL! neq 0 (
                reg add "!ROOTKEY!" /v "!FILE!" /t REG_DWORD /d 0 /f >nul 2>&1

                if !ERRORLEVEL! == 0 (
                    echo Installed: !FILE!
                )
            ) else (
			echo This file is already registered...
			)
        )
    )
)
goto :eof

:wait
set /A TIMER=%~1+1
>nul 2>&1 PING 127.0.0.1 -n %TIMER%
exit /b

:addMissingFiles
cls
<NUL set /p=AMD OpenCL x64 driver file missing...
POWERSHELL -nop -c "$Url='https://download.amd.com/dir/bin/amdocl64.dll/64CB5B3Ed36000/amdocl64.dll';function Size-To-Human-Readable([uint64]$size){$suffix='bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB';$i = 0;while ($size -gt 1kb) {$size=$size / 1kb;$i++}"^""{0:N1} {1}"^"" -f $size, $suffix[$i]};$str_size=(Invoke-WebRequest -UseBasicParsing -Uri $Url -Method Head).Headers.'Content-Length';$tmp_size=[uint64]::Parse($str_size);$Size=Size-To-Human-Readable $tmp_size;Write-Host " Downloading 'amdocl64.dll' ($Size)";Start-BitsTransfer -Priority Foreground -Source $Url -Destination '%WinDir%\System32\amdocl64.dll'"
echo/
echo Download Complete.
call :wait 2
cls
echo Running AMD OpenCL Driver Auto Detection
echo ========================================
echo/
echo Scanning '%SYSTEMROOT%\system32' for 'amdocl*.dll' files, please wait...
echo/
exit /b