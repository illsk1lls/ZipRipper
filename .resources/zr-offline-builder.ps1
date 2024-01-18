Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$xaml='<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="ProgressBar" Height="64" Width="200"
		WindowStartupLocation="CenterScreen"
		WindowStyle="None"
		Background="#333333"
		AllowsTransparency="True">
	<Canvas>
    <TextBlock Name="TextBlock" Text=" Preparing Download..." Foreground="#eeeeee" FontWeight="Bold">
    </TextBlock>
		<ProgressBar Canvas.Top="20" Width="200" Height="20" Name="DownloadProgress"/>
		<ProgressBar Canvas.Top="44" Width="200" Height="20" Name="DownloadProgressTotal"/>
	</Canvas>
</Window>'

$reader=(New-Object System.Xml.XmlNodeReader $xaml);$window=[Windows.Markup.XamlReader]::Load($reader)

$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})

$progressBar=$window.FindName("DownloadProgress")
$progressBarTotal=$window.FindName("DownloadProgressTotal")
$TextBlock=$window.FindName("TextBlock")

function Update-Gui (){
    $window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}

function Build () {
	if (Test-Path -Path ".\ZR-Builder") {
		Remove-Item -Path ".\ZR-Builder" -Recurse -Force
	}
	New-Item -Path ".\" -Name "ZR-Builder" -ItemType "directory"
	downloadFile "https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/zipripper.png" ".\ZR-Builder\zipripper.png";
	$progressBarTotal.Value = 1
	Update-Gui
	downloadFile "https://www.7-zip.org/a/7zr.exe" ".\ZR-Builder\7zr.exe";
	$progressBarTotal.Value = 15
	Update-Gui
	downloadFile "https://www.7-zip.org/a/7z2301-x64.exe" ".\ZR-Builder\7z2301-x64.exe";
	$progressBarTotal.Value = 27
	Update-Gui
	downloadFile "https://www.7-zip.org/a/7z2300-extra.7z" ".\ZR-Builder\7zExtra.7z";
	$progressBarTotal.Value = 45
	Update-Gui
	downloadFile "https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z" ".\ZR-Builder\winX64_1_JtR.7z";
	$progressBarTotal.Value = 65
	Update-Gui
	downloadFile "https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip" ".\ZR-Builder\perlportable.zip";
	$progressBarTotal.Value = 80
	$progressBar.Value = 0
	$TextBlock.Text=" Building zr-offline.txt... "
	Update-Gui
	.\ZR-Builder\7zr.exe x -y ".\ZR-Builder\7zExtra.7z" -o".\ZR-Builder\"
	$progressBarTotal.Value = 85
	$progressBar.Value = 35
	$TextBlock.Text=" Building zr-offline.txt... "
	Update-Gui
	.\ZR-Builder\7za.exe x -y ".\ZR-Builder\7z2301-x64.exe" -o".\ZR-Builder\"
	$progressBarTotal.Value = 90
	$progressBar.Value = 80
	$TextBlock.Text=" Building zr-offline.txt... "
	Update-Gui
	.\ZR-Builder\7z.exe a '.\ZR-Builder\resources.exe' '.\ZR-Builder\winX64_1_JtR.7z' '.\ZR-Builder\perlportable.zip' '.\ZR-Builder\7zr.exe' '.\ZR-Builder\7zExtra.7z' '.\ZR-Builder\zipripper.png' -sfx'.\ZR-Builder\7zCon.sfx' -pDependencies
	$opath=(gc $env:ProgramData\launcher.ZipRipper)
 	$opath=$opath.Replace('"','')
  	$opath=$opath + "zr-offline.txt"
 	Move-Item -Path ".\ZR-Builder\resources.exe" -Destination $opath -Force
	$progressBarTotal.Value = 100
	$progressBar.Value = 100
	$TextBlock.Text=" Build Completed!"
	Update-Gui
	Remove-Item -Path ".\ZR-Builder" -Recurse -Force
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
	   if($progressBar.Value -ne 0){$TextBlock.Text=$targetFile.Trim('"') -Replace(".*\\","");$TextBlock.Text=" Downloading " + $TextBlock.Text}
	   if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;Update-Gui}
   }
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}

$window.Add_ContentRendered({
	Build
	$window.Close()
})

$window.Show()

$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
