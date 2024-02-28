@echo off
cls
echo OpenCL Driver (ICD) Fix for AMD GPU's
echo By Patrick Trumpis (https://github.com/ptrumpis/OpenCL-AMD-GPU)
echo Inspired by https://stackoverflow.com/a/28407851
echo:
echo:

>nul 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\config\system" && (
    goto :run
) || (
    echo Execution stopped
    echo =================
    echo This script requires administrator rights.
    echo Please run it again as administrator.
    echo You can right click the file and select 'Run as administrator'

    echo:
    pause
    exit /b 1
)

:run
SETLOCAL EnableDelayedExpansion

SET ROOTKEY64=HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors
SET ROOTKEY32=HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Khronos\OpenCL\Vendors

echo Currently installed OpenCL Client Driver's - 64bit
echo ==================================================
for /f "tokens=1,*" %%A in ('reg query %ROOTKEY64%') do (
    echo %%A - %%B
)
echo:

echo Currently installed OpenCL Client Driver's - 32bit
echo ==================================================
for /f "tokens=1,*" %%A in ('reg query %ROOTKEY32%') do (
    echo %%A - %%B
)
echo:

echo:
echo This script will now attempt to find and install unregistered OpenCL AMD drivers from Windows (Fast Scan).

:askUserFastScan
set "INPUT="
set /P "INPUT=Do you want to continue? (Y/N): "
if /I "!INPUT!" == "Y" (
    echo:
    echo:
    goto :scanFilesFast
) else if /I "!INPUT!" == "N" (
    goto :exit
) else (
    goto :askUserFastScan
)

:scanFilesFast
echo Running AMD OpenCL Driver Auto Detection
echo ========================================
echo:

echo Scanning '%SYSTEMROOT%\system32' for 'amdocl*.dll' files, please wait...
echo:

cd /d %SYSTEMROOT%\system32
call :registerMissingClientDriver

echo:
echo Fast Scan complete.
echo:

echo:
echo This script will now attempt to find and install any unregistered OpenCL AMD drivers found on your computer (Full Scan).

:askUserFullScan
set "INPUT="
set /P "INPUT=Do you want to continue? (Y/N): "
if /I "!INPUT!" == "Y" (
    echo:
    echo:
    goto :scanFilesFull
) else if /I "!INPUT!" == "N" (
    goto :complete
) else (
    goto :askUserFullScan
)


:scanFilesFull
echo Now scanning your PATH for 'amdocl*.dll' files, please wait...
echo:

for %%A in ("%path:;=";"%") do (
    if "%%~A" neq "" (
        cd /d %%A
        call :registerMissingClientDriver
    )
)

echo:
echo Full Scan complete.
echo:

:complete
echo:
echo Done.
echo:
pause

:exit
exit /b 0

:registerMissingClientDriver
for /r %%f in (amdocl*dll) do (
    set FILE="%%~dpnxf"

    for %%A in (amdocl.dll amdocl12cl.dll amdocl12cl64.dll amdocl32.dll amdocl64.dll) do (
        if "%%~nxf"=="%%A" (
            echo Found: !FILE!

            echo !FILE! | findstr /C:"_amd64_" >nul
            if !ERRORLEVEL! == 0 (
                set "ROOTKEY=!ROOTKEY64!"
            ) else (
                set FILE_BIT=!FILE:~-7,-5!
                if !FILE_BIT! == 64 (
                    set "ROOTKEY=!ROOTKEY64!"
                ) else (
                    set "ROOTKEY=!ROOTKEY32!"
                )
            )

            reg query !ROOTKEY! >nul 2>&1
            if !ERRORLEVEL! neq 0 (
                reg add !ROOTKEY! /f
                echo Added Key: !ROOTKEY!
            )

            reg query !ROOTKEY! /v !FILE! >nul 2>&1

            if !ERRORLEVEL! neq 0 (
                reg add !ROOTKEY! /v !FILE! /t REG_DWORD /d 0 /f >nul 2>&1

                if !ERRORLEVEL! == 0 (
                    echo Installed: !FILE!
                )
            )
        )
    )
)
goto :eof
