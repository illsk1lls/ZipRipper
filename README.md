# ZipRipper - A CMD script to crack password protected ZIP, RAR, 7z, and PDF files, using JohnTheRipper

<p align="center">
<img src="https://github.com/illsk1lls/ZipRipper/blob/main/.resources/zipripper.png?raw=true"><br>
*<sup>Powered by JohnTheRipper</sup>*
</p>

**Credit To:**<br>
JohnTheRipper - <a href="https://github.com/openwall/john">https://github.com/openwall/john</a><br>
cyclone_hk Wordlist(Hosted by Weakpass) - <a href="https://github.com/cyclone-github/wordlist">https://github.com/cyclone-github/wordlist</a><br>
7zip - <a href="https://www.7-zip.org/">https://www.7-zip.org/</a><br>
StarwberryPerl(Portable) - <a href="https://strawberryperl.com/releases.html">https://strawberryperl.com/releases.html</a><br>

**<p align="center">Instructions:</p>**

$${\color{yellow}1.) \space Double-click \space the \space script, \space and \space select \space a \space password \space protected \space ZIP, \space RAR, \space 7z, \space or \space PDF \space file}$$<br>

$${\color{yellow}2.) \space Wait \space for \space password..}$$<br>

When a password is found an alert window will appear, and the password(s) will be<br>
saved to the users desktop as: ZipRipper-Passwords.txt

*If the script is interrupted normally (by pressing the 'q' key to quit or the 'red x', once), resume will be enabled<br>.*
*A MD5 hash is created for each job that is used to store the resume data in: %AppData%\ZR-InProgress\\[MD5HASH]<br>*
*to ensure multiple files with the same name can have InProgress jobs simultaneously. If a pending job is found the<br>*
*user is presented with the options of either resuming the job, or bypassing the resume feature and starting a new job.<br>*
*Note: When a job is completed the resume data is removed. All resume data can be cleared by clicking the center of John's tie*

To set an alternate wordlist, click John's mouth and select an option before starting the session. (Clicking an option will register your selection and quietly dismiss the menu)

Current version provides support for hardware acceleration via OpenCL for:<br>
nVidia "GeForce" & "Quadro" and AMD "Radeon RX" & "Radeon Pro" cards.<br>

*ZIP, RAR, 7z, and PDF filetypes are supported

ZipRipper is portable, there are two different running modes; Online Mode, and Offline mode...

**Online Mode:** ZipRipper gathers its resources from the web (JohnTheRipper, 7zip, and Portable Perl).<br>
Only the script itself and an internet connection are required for this mode.<br>

**Offline Mode:** ZipRipper uses/requires a local resource file [zr-offline.txt]. **The presence of [zr-offline.txt] in<br>**
**the same folder as the script is required and will force offline mode.** An internet connection is not needed for this mode.<br>

**[zr-offline.txt] creator:** Click the letters JtR in John's hat to create [zr-offline.txt], you can then relaunch in offline mode, or package the offline/portable script for use at a later time.

*UNC Paths and redirected folders are supported.*
