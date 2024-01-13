@ECHO OFF
CALL :CHECKCONNECTION
TITLE ^[zr-offline.txt^] ZipRipper Resource Creator
CD /D "%~dp0"
IF EXIST "%ProgramData%\ZR-Temp\*" >nul 2>&1 RD "%ProgramData%\ZR-Temp" /S /Q
MD "%ProgramData%\ZR-Temp"
PUSHD "%ProgramData%\ZR-Temp"
<NUL set /p=Getting required dependencies, please wait...
POWERSHELL -nop -c "Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -o '%ProgramData%\ZR-Temp\7zr.exe';Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2301-x64.exe -o '%ProgramData%\ZR-Temp\7z2301-x64.exe';Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2300-extra.7z -o '%ProgramData%\ZR-Temp\7zExtra.7z';Invoke-WebRequest -Uri https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/zipripper.png -o '%ProgramData%\ZR-Temp\zipripper.png';Start-BitsTransfer -Priority Foreground -Source https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z -Destination '%ProgramData%\ZR-Temp\winX64_1_JtR.7z'";"Start-BitsTransfer -Priority Foreground -Source https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip -Destination '%ProgramData%\ZR-Temp\perlportable.zip'"
>nul 2>&1 7zr.exe x -y "%ProgramData%\ZR-Temp\7zExtra.7z" -o"%ProgramData%\ZR-Temp\"
>nul 2>&1 7za.exe x -y "%ProgramData%\ZR-Temp\7z2301-x64.exe" -o"%ProgramData%\ZR-Temp\"
ECHO Done
ECHO/
<NUL set /p=Building ^[zr-offline.txt^]...
>nul 2>&1 7z a resources.exe "winX64_1_JtR.7z" "perlportable.zip" "7zr.exe" "7zExtra.7z" "zipripper.png" -sfx7zCon.sfx -pDependencies
IF EXIST "zr-offline.txt" >nul 2>&1 DEL "zr-offline.txt" /F /Q
>nul 2>&1 REN resources.exe zr-offline.txt
POPD
>nul 2>&1 COPY /Y "%ProgramData%\ZR-Temp\zr-offline.txt" "%~dp0"
>nul 2>&1 RD "%ProgramData%\ZR-Temp" /S /Q
ECHO Done
ECHO/
ECHO ^[zr-offline.txt^] is located in the same folder as the script. ;^)
ECHO/
PAUSE
GOTO :EOF

:CHECKCONNECTION
TITLE Internet Not Detected!
PING -n 1 "google.com" | FINDSTR /r /c:"[0-9] *ms">nul
IF NOT %errorlevel%==0 (
	ECHO Internet connection required to create ^[zr-offline.txt^]
	ECHO/
	PAUSE
	GOTO :EOF
)
EXIT /b