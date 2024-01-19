Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$xaml2='<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="ProgressBar" Height="64" Width="200"
		WindowStartupLocation="CenterScreen"
		WindowStyle="None"
		Background="#333333"
		AllowsTransparency="True">
	<Canvas>
    <TextBlock Name="Info" Text=" Preparing Download..." Foreground="#eeeeee" FontWeight="Bold">
    </TextBlock>
		<ProgressBar Canvas.Top="20" Width="200" Height="20" Name="DownloadProgress"/>
		<ProgressBar Canvas.Top="44" Width="200" Height="20" Name="DownloadProgressTotal"/>
	</Canvas>
</Window>'

$reader2=(New-Object System.Xml.XmlNodeReader $xaml2);$window2=[Windows.Markup.XamlReader]::Load($reader2)

$window2.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})

$progressBar=$window2.FindName("DownloadProgress")
$progressBarTotal=$window2.FindName("DownloadProgressTotal")
$info=$window2.FindName("Info")

function Update-Gui (){
    $window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}

function Build () {
	if (Test-Path -Path ".\ztmp") {
		Remove-Item -Path ".\ztmp" -Recurse -Force
	}
	New-Item -Path ".\" -Name "ztmp" -ItemType "directory"
	downloadFile "https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/zipripper.png" ".\ztmp\zipripper.png";
	$progressBarTotal.Value = 1
	Update-Gui
	downloadFile "https://www.7-zip.org/a/7zr.exe" ".\ztmp\7zr.exe";
	$progressBarTotal.Value = 15
	Update-Gui
	downloadFile "https://www.7-zip.org/a/7z2301-x64.exe" ".\ztmp\7z2301-x64.exe";
	$progressBarTotal.Value = 27
	Update-Gui
	downloadFile "https://www.7-zip.org/a/7z2300-extra.7z" ".\ztmp\7zExtra.7z";
	$progressBarTotal.Value = 45
	Update-Gui
	downloadFile "https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z" ".\ztmp\winX64_1_JtR.7z";
	$progressBarTotal.Value = 65
	Update-Gui
	downloadFile "https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip" ".\ztmp\perlportable.zip";
	$progressBarTotal.Value = 80
	$progressBar.Value = 0
	$info.Text=" Building zr-offline.txt... "
	Update-Gui
	.\ztmp\7zr.exe x -y ".\ztmp\7zExtra.7z" -o".\ztmp\"
	$progressBarTotal.Value = 85
	$progressBar.Value = 35
	Update-Gui
	.\ztmp\7za.exe x -y ".\ztmp\7z2301-x64.exe" -o".\ztmp\"
	$progressBarTotal.Value = 90
	$progressBar.Value = 80
	Update-Gui
	.\ztmp\7z.exe a '.\ztmp\resources.exe' '.\ztmp\winX64_1_JtR.7z' '.\ztmp\perlportable.zip' '.\ztmp\7zr.exe' '.\ztmp\7zExtra.7z' '.\ztmp\zipripper.png' -sfx'.\ztmp\7zCon.sfx' -pDependencies
	Move-Item -Path ".\ztmp\resources.exe" -Destination ".\zr-offline.txt" -Force
	$progressBarTotal.Value = 100
	$progressBar.Value = 100
	$info.Text=" Build Completed!"
	Update-Gui
	Remove-Item -Path ".\ztmp" -Recurse -Force
	Sleep 3
}

function DownloadFile($url,$targetFile)
{
   $uri = New-Object "System.Uri" "$url"
   $request = [System.Net.HttpWebRequest]::Create($uri)
   $request.set_Timeout(15000)
   $response = $request.GetResponse()
   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
   $responseStream = $response.GetResponseStream()
   $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
   $buffer = new-object byte[] 10KB
   $count = $responseStream.Read($buffer,0,$buffer.length)
   $downloadedBytes = $count
   while ($count -gt 0)
   {
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
	   $roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
	   $progressBar.Value = $roundedPercent
	   if($progressBar.Value -ne 0){$info.Text=$targetFile.Trim('"') -Replace(".*\\","");$info.Text=" Downloading " + $info.Text}
	   if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;Update-Gui}
   }
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}

$window2.Add_ContentRendered({
	Build
	$window2.Close()
})

$window2.Show()

$appContext2=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext2)