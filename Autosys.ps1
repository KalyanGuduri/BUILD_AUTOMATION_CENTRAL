# Title       :  Script for Packaging Autosys Scripts
#
# Description :  Scans the Items in folder list SVN
#                Picks the file with the Specified Jira 
#                Organize it and Upload
#           

$env:Path += "C:\Program Files\Git\bin"
$env:Path += "C:\Program Files\Git\cmd"
$ErrorActionPreference='Ignore'
git config --global http.sslVerify false     

$script_start_datetime = get-date
Write-Output "Autosys.ps1 started at $script_start_datetime" #| out-file -Append Timestamps.txt -Encoding ascii;
write-output "Autosys.ps1 process ID is $PID"

$argument = $args[0]
$argument_2 = $argument.Replace('\\\\','\')
cd $argument_2
echo "currently in $argument_2"

Write-Output "Checking If Git is Installed $(Date) " #>>Timestamps.txt
git --version >$NULL 2>$NULL
if (-not($?))
{
write-output "Git is Not installed on your machine"
Write-Output "Install Git Community from Software Center"
Write-output "Ensure that git is working from the windows cmd prompt"
write-output "Set the git bin path as environment variable"
#pause
exit

}
Write-Output "Checking if User has Access $(Date) " #>>Timestamps.txt
git ls-remote  -h "https://wfs-github.wellsfargo.com/IHUB/Build_Automation_Central.git" >$NULL 2>$NULL
if (-not($?))
{
write-output "Not Able to ACCESS Build Automation Repo"
write-output "Ensure that you have the right access"
write-output "If your password has changed update it CREDENTIAL MANAGER"

#pause
#exit

}
# ================ Cleanup for previous failed runs ==========================

$date_here = get-date
Write-Output "Previous run cleanup check process started at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;

if (Test-Path svn_export.lst ) {Remove-Item svn_export.lst}
if (Test-Path PS_OUTPUT.lst ) {Remove-Item PS_OUTPUT.lst}
if (Test-Path output.xml ) {Remove-Item output.xml}
if (Test-Path out.lst ) {Remove-Item out.lst }

$date_here = get-date
Write-Output "Previous run cleanup check process ended at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;

# ================ Variable Declaration ==========================

$date_here = get-date
Write-Output "Initial configuration process started at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;

$Loc = Get-Location
$cwd = $Loc.Path
$Locs = import-csv .\input* -Header Jira
$inputJira = @()
$inputJira += $locs.Jira | Sort-Object -Unique | ? {$_}
$AppProps = convertfrom-stringdata (get-content ./properties.txt -raw)
$Svn_Location = $AppProps.'app.svn_location'
$Upload_folder = $AppProps.'app.package_name'
$Upload_path = $AppProps.'app.upload_location'
if ($Upload_path -like '*tree/master*')
{
$Upload_path = $Upload_path.replace('tree/master','trunk')
}
$folder_list = @();

if (($Svn_Location -eq "") -or ($Upload_folder -eq "") -or ($Upload_path -eq ""))
{
   # Write-Host "Please check the properties file" -ForegroundColor Red
	Write-Output "Please check the properties file"
    $date_here = get-date
    Write-Output "Initial configuration process failed with configuration error at $date_here"	
    exit
}


$Iteration_List1 = @()
$Iteration_List1 += svn list $Upload_path
$Folder="$Upload_folder/"
if ( $Iteration_List1.Contains($Folder))
{
#Write-Host "The Package Name Already exists In GIT Please Rename it in the Properties File " -ForegroundColor Red
Write-Output "The Package Name Already exists In GIT Please Rename it in the Properties File " 
$date_here = get-date
Write-Output "Process ended with Package Name Already exists In GIT error at $date_here"
exit
}

$date_here = get-date
Write-Output "Initial configuration process ended at $date_here" # | out-file -Append Timestamps.txt -Encoding ascii;

# ================ Find the Jiras on SVN ==========================

$date_here = get-date
Write-Output "Scanning GIT for input JIRA process started at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;

#Write-Host "`r`nFinding Jiras On GIT ....."
Write-Output "`r`nFinding Jiras On GIT ....."

.\Autosys_Log.ps1 Autosys

cd $cwd

$Timestamps = get-content .\Timestamps.txt
write-output $Timestamps

Rename-item AUTOMATIC_DG $Upload_folder

    # ================ Uploading the package ==========================
	
$date_here = get-date
Write-Output "Uploading package to GIT for input JIRA process started at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;	
    
    Write-Output "`r`nUploading the Package..."
    
    svn checkout $Upload_path --depth empty    > $null

    Move-Item  -path $Upload_folder -destination $Upload_path.Split('/')[-2] 
	write-output $LASTEXITCODE

    #Write-Output "`r`nReview the Package before Uploading...`r`n"
    #$Upload = Read-Host -Prompt 'Do You want To Upload to GIT (Y/N)'
	$Upload = 'Y'
    $svn_folder = $Upload_path.Split('/')[-2] 
    if($Upload -eq 'Y')
    {
    Write-Output "`r`nCommiting..."

    SVN add $cwd\$svn_folder\$Upload_folder > $null
    SVN commit $svn_folder\$Upload_folder -m "$Upload_folder" > $null

    }


     Write-Output "`r`nJOB COMPLETED !`r`n"

$date_here = get-date
Write-Output "Uploading package to GIT for input JIRA process ended at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;		 

# ================ CleanUp ==========================

$date_here = get-date
Write-Output "Cleanup for current temp files process started at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;

cd $cwd
#Remove-Item svn_export.lst 
#Remove-Item PS_OUTPUT.lst
#Remove-Item output.xml
#Remove-Item out.lst
Remove-Item $Svn_Location.Split('/')[-1] -Recurse -Force
Remove-Item $($Upload_path.Split('/')[-2]) -Recurse -Force

$date_here = get-date
Write-Output "Cleanup for current temp files process ended at $date_here" #| out-file -Append Timestamps.txt -Encoding ascii;

$script_end_datetime = get-date
#$script_name = $MyInvocation.MyCommand.Name
Write-Output "Autosys.ps1 ended at $script_end_datetime" #| out-file -Append Timestamps.txt -Encoding ascii;
$DATE_DIFF = $script_end_datetime - $script_start_datetime
$DIFF_HOURS = $DATE_DIFF.Hours
 $DIFF_MINS = $DATE_DIFF.Minutes
 $DIFF_SECS = $DATE_DIFF.Seconds
 $DIFF_TOT = "$DIFF_HOURS"+":"+"$DIFF_MINS"+":"+"$DIFF_SECS"
 Write-Output "Total run time is $DIFF_TOT" #| out-file -Append Timestamps.txt -Encoding ascii;
