Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$xaml2='<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="Building [zr-offline.txt]" Height="64" Width="200"
		WindowStartupLocation="CenterScreen"
		WindowStyle="None"
		Background="#333333"
		AllowsTransparency="True">
	<Canvas>
    <TextBlock Name="Info" Text=" Preparing Download..." Foreground="#eeeeee" FontWeight="Bold">
    </TextBlock>
		<ProgressBar Canvas.Top="20" Width="200" Height="20" Name="Progress"/>
		<ProgressBar Canvas.Top="44" Width="200" Height="20" Name="Progress2"/>
	</Canvas>
</Window>'

$reader=(New-Object System.Xml.XmlNodeReader $xaml2);$form=[Windows.Markup.XamlReader]::Load($reader)

$form.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})

$progressBar=$form.FindName("Progress")
$progressTotal=$form.FindName("Progress2")
$info=$form.FindName("Info")

function Update-Gui (){
    $form.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}

function Build () {
	if (Test-Path -Path 'C:\ProgramData\ztmp') {
		Remove-Item -Path 'C:\ProgramData\ztmp' -Recurse -Force
	}
	New-Item -Path 'C:\ProgramData' -Name 'ztmp' -ItemType "directory"
	downloadFile 'https://raw.githubusercontent.com/illsk1lls/ZipRipper/main/.resources/zipripper.png' 'C:\ProgramData\ztmp\zipripper.png'
	$progressTotal.Value=1
	Update-Gui
	downloadFile 'https://www.7-zip.org/a/7zr.exe' 'C:\ProgramData\ztmp\7zr.exe'
	$progressTotal.Value=15
	Update-Gui
	downloadFile 'https://www.7-zip.org/a/7z2301-x64.exe' 'C:\ProgramData\ztmp\7z2301-x64.exe'
	$progressTotal.Value=27
	Update-Gui
	downloadFile 'https://www.7-zip.org/a/7z2300-extra.7z' 'C:\ProgramData\ztmp\7zExtra.7z'
	$progressTotal.Value=45
	Update-Gui
	downloadFile 'https://github.com/openwall/john-packages/releases/download/jumbo-dev/winX64_1_JtR.7z' 'C:\ProgramData\ztmp\winX64_1_JtR.7z'
	$progressTotal.Value=65
	Update-Gui
	downloadFile 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.38.0.1-64bit-portable.zip' 'C:\ProgramData\ztmp\perlportable.zip'
	$progressTotal.Value=80
	$progressBar.Value=0
	$info.Text=' Building zr-offline.txt... '
	Update-Gui
	C:\ProgramData\ztmp\7zr.exe x -y 'C:\ProgramData\ztmp\7zExtra.7z' -o'C:\ProgramData\ztmp\'
	$progressTotal.Value=85
	$progressBar.Value=35
	Update-Gui
	C:\ProgramData\ztmp\7za.exe x -y 'C:\ProgramData\ztmp\7z2301-x64.exe' -o'C:\ProgramData\ztmp\'
	$progressTotal.Value=90
	$progressBar.Value=80
	Update-Gui
	C:\ProgramData\ztmp\7z.exe a 'C:\ProgramData\ztmp\resources.exe' 'C:\ProgramData\ztmp\winX64_1_JtR.7z' 'C:\ProgramData\ztmp\perlportable.zip' 'C:\ProgramData\ztmp\7zr.exe' 'C:\ProgramData\ztmp\7zExtra.7z' 'C:\ProgramData\ztmp\zipripper.png' -sfx'C:\ProgramData\ztmp\7zCon.sfx' -pDependencies
	$m=([IO.File]::ReadAllLines('C:\ProgramData\launcher.ZipRipper')).Replace('"','')
	$fn='zr-offline.txt'
	Move-Item -Path "C:\ProgramData\ztmp\resources.exe" -Destination "$m$fn" -Force
	$progressTotal.Value=100
	$progressBar.Value=100
	$info.Text=" Build Completed!"
	Update-Gui
	Remove-Item -Path 'C:\ProgramData\ztmp' -Recurse -Force
	}

function DownloadFile($url,$targetFile)
{
   $uri=New-Object "System.Uri" "$url"
   $request=[System.Net.HttpWebRequest]::Create($uri)
   $request.set_Timeout(15000)
   $response=$request.GetResponse()
   $totalLength=[System.Math]::Floor($response.get_ContentLength()/1024)
   $responseStream=$response.GetResponseStream()
   $targetStream=New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
   $buffer=new-object byte[] 10KB
   $count=$responseStream.Read($buffer,0,$buffer.length)
   $downloadedBytes=$count
   while ($count -gt 0)
   {
       $targetStream.Write($buffer, 0, $count)
       $count=$responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes=$downloadedBytes + $count
	   $roundedPercent=[int]((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
	   $progressBar.Value=$roundedPercent
	   if($progressBar.Value -ne 0){$info.Text=$targetFile.Trim('"') -Replace(".*\\",'');$info.Text=' Downloading ' + $info.Text}
	   if($progressBar.Value -ne $lastpercent){$lastpercent=$progressBar.Value;Update-Gui}
   }
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}

$form.Add_ContentRendered({Build;$form.Close()})

$form.Show();$appContext=New-Object System.Windows.Forms.ApplicationContext;[void][System.Windows.Forms.Application]::Run($appContext)