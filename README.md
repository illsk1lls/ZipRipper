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

*<p align="center">When a password is found an alert window will appear, and the password(s) will be<br>*
*saved to the users desktop as:* ZipRipper-Passwords.txt</p>

**ZipRipper is portable, there are two different running modes; Online Mode, and Offline mode...**<br>

**Online Mode:** ZipRipper gathers its resources from the web (JohnTheRipper, 7zip, and Portable Perl).<br>
Only the script itself and an internet connection are required for this mode.<br>

**Offline Mode:** ZipRipper uses/requires a local resource file [zr-offline.txt]. **The presence of [zr-offline.txt] in<br>**
**the same folder as the script is required and will force offline mode.** An internet connection is not needed for this mode.<br>

**[zr-offline.txt] creator:** Click the letters JtR in John's hat to create [zr-offline.txt], you can then relaunch in offline mode, or package the offline/portable script for use at a later time.<br>

*If the script is interrupted normally (by pressing the 'q' key to quit or the 'red x', once), resume will be enabled<br>.*
*A MD5 hash is created for each job that is used to store the resume data in: %AppData%\ZR-InProgress\\[MD5HASH]<br>*
*to ensure multiple files with the same name can have InProgress jobs simultaneously. If a pending job is found the<br>*
*user is presented with the options of either resuming the job, or bypassing the resume feature and starting a new job.<br>*
*Note: When a job is completed the resume data is removed. All resume data can be cleared by clicking the center of John's tie*

**Alternate wordlist options:**<br>
Click John's mouth and select an option before starting the session. (Clicking an option will register your selection and quietly dismiss the menu, selecting no option will use the default JtR wordlist)<br>

It is possible to change the built in alternate wordlist. The included cyclone_hk alternate<br>
wordlist is an optional 667MB download, and 2.3GB expanded on disk. **Although the easiest way to use an additional wordlist other than the built in Cyclone alternate, is the Custom wordlist option, which allows you to select a local file.**<br>

Examples of how to change the built in alternate wordlist;<br>
-For a lightweight variant of the RockYou wordlist(optional 133MB uncompressed<br>
download, and 133MB on disk) you would change lines 52-55 to the following<br>
```
SET WORDLISTNAME="RockYou"
SET WORDLISTADDR="https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
SET WORDLIST7z=""
SET WORDLISTTXT="RockYou.txt"
```
-For Cyclone.hashesorg.hashkiller.combined wordlist(optional 6.53GB download,<br>
and 15.02GB expanded on disk) you would change lines 52-55 to the following<br>
```
SET WORDLISTNAME="Combined"
SET WORDLISTADDR="https://download.weakpass.com/wordlists/1927/cyclone.hashesorg.hashkiller.combined.txt.7z"
SET WORDLIST7z="cyclone.hashesorg.hashkiller.combined.txt.7z"
SET WORDLISTTXT="cyclone.hashesorg.hashkiller.combined.txt"
```
-Etc...<br>
More wordlists can be found at <a href="https://weakpass.com/wordlist">https://weakpass.com/wordlist</a> and various other<br>
places around the web..<br>

The built in alternate wordlist supports direct download links to:<br>
-7z archives containing a text file<br>
-Raw unarchived txt files.<br>
If a raw text file is used, leave WORDLIST7z="" as shown in the RockYou variant above,<br>
otherwise WORDLIST7z="DownloadedArchiveName.7z" as shown in the Combined option above.<br>

**Current version provides support for hardware acceleration via OpenCL for:**<br>
nVidia "GeForce" & "Quadro" and AMD "Radeon RX" & "Radeon Pro" cards.<br>

*UNC Paths and redirected folders are supported.*<br>