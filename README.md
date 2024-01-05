# ZipRipper - A CMD script to crack password protected ZIP, RAR, 7z, and PDF files, using JohnTheRipper

Credit To: <br>

JohnTheRipper - <a href="https://github.com/openwall/john">https://github.com/openwall/john</a><br>
7zip - <a href="https://www.7-zip.org/">https://www.7-zip.org/</a><br>
StarwberryPerl(Portable) - <a href="https://strawberryperl.com/releases.html">https://strawberryperl.com/releases.html</a><br>

1.) Drag-and-Drop a password protected ZIP, RAR, 7z, or PDF file onto the script<br>

2.) Wait for password..<br>

-Alternatively, you can double-click the script to browse to a file with GUI, and the<br>
script will relaunch itself with the file selected.
-Limited CLI is also available

When a password is found an alert window will appear, and the password(s) will be<br>
saved to the users desktop as: ZipRipper-Passwords.txt

Current version provides support for hardware acceleration via OpenCL for:<br>
nVidia "GeForce" & "Quadro" and AMD "Radeon RX" & "Radeon Pro" cards.<br>

*ZIP, RAR, 7z, and PDF filetypes are supported

*Offline Mode can be enabled by putting zr-offline.txt (from the .resources folder) in the same folder<br>
as the script.
