# Script to get all the Jira numbers present on Github
# Also mentions if the Jira is part of DB Unix autosys or informatica
#
# Removes all the previous variables and if and error occurs proceed 


Remove-Variable * -ErrorAction SilentlyContinue
$ErrorActionPreference = 'SilentlyContinue'
$cwd = get-location
Remove-Item .\Timestamps.txt -Force 2>>$null
$script_start_datetime = get-date
$script_name = $MyInvocation.MyCommand.Name
"$script_name started at $script_start_datetime" >> Timestamps.txt
"Checking If Git is Installed $(Date) " >>Timestamps.txt
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
"Checking if User has Access $(Date) " >>Timestamps.txt
git ls-remote  -h "https://wfs-github.wellsfargo.com/IHUB/Build_Automation_Central.git" >$NULL 2>$NULL
if (-not($?))
{
write-output "Not Able to ACCESS Build Automation Repo"
write-output "Ensure that you have the right access"
write-output "If your password has changed update it CREDENTIAL MANAGER"

#pause
#exit

}

# ================================ Input location =======================================
if ($args[0] -eq $null)
{
    $SVN_ETL_LOCATION="Autosys"
    $SVN_DB_LOCATION="Database"
    $SVN_UNIX_LOCATION="Unix"
    $SVN_AUTOSYS_LOCATION="Autosys"
    $SVN_OUT_PATH="https://wfs-github.wellsfargo.com/IHUB/Build_Automation_Central/trunk/Component_List"
	$SVN_OUT_PATH1="https://wfs-github.wellsfargo.com/IHUB/Build_Automation_Central/trunk/Impact_List"
}
else
{
    $SVN_ETL_LOCATION=$args[0]
   <# $ETL_FOLDER = $SVN_ETL_LOCATION.split('/')[-2]
	$ETL_SUBFOLDER = $SVN_ETL_LOCATION.split('/')[-1]
	$SVN_ETL_LOCATION = "$ETL_FOLDER"+"/"+"$ETL_SUBFOLDER"
    $SVN_DB_LOCATION="Database"
    $SVN_UNIX_LOCATION="Unix"
    $SVN_AUTOSYS_LOCATION="Autosys"
    $SVN_OUT_PATH=$args[4]
	$SVN_OUT_PATH1="https://wfs-github.wellsfargo.com/IHUB/Build_Automation_Central/trunk/Impact_List"
    $SCRIPT_LOCATION=$args[5]
    cd $SCRIPT_LOCATION #>
}

Remove-Item .\output.csv -Force 2>>$null
Remove-Item .\output.xml -Force 2>>$null
#Remove-Item .\wf_jira.csv -Force 2>>$null
Remove-Item .\build_automation_central -Force -Recurse >$null 
Remove-Item .\to_upload -Force -Recurse >$null 

$input_jira = import-csv .\input* -Header Jira

# ================================ GET GIT LOGS IN XML FORMAT =======================================
function getlog ($location)
{
"Working on getting the logs $(Date) " >>Timestamps.txt
$OFS = "`r`n"
Git clone --no-checkout "https://wfs-github.wellsfargo.com/IHUB/Build_Automation_Central.git"  
cd Build_Automation_Central
[String]$data = git log  --name-status --pretty=format:'>%H|%s|%an|%cI|%f;'  -- $location 
$log = $data.Split(">")
$test=@()
$path=(Get-Location).Path
$stream = [System.IO.StreamWriter] "$path\t.txt"
  $stream.WriteLine('<?xml version="1.0"?>')
  $stream.WriteLine('<log>')
foreach ($entry in $log)


{
    $tags = $entry.split('|')
    $jira_files = $tags[-1].Split(';')
    $jira = $jira_files[0]
    $files = $jira_files[1]
    $rev = $tags[0]
    if ($rev -ne "")
    
    {
        $author =$tags[2]
        $dates=$tags[3]
        
        $d1 = "<logentry revision="+'"'+$rev+'"'+">"
         $stream.WriteLine($d1)
          $stream.WriteLine("<author>$author</author>")
          $stream.WriteLine("<date>$dates</date>")
          $stream.WriteLine("<paths>")
        
        if ($files -ne $null)
        
        
        {
            $lines=$files.split("`r`n")
            $paths =@()
            
            foreach ($ent in $lines )
                
            {
                $sp=$ent.split("`t")
                if ($sp[0] -ne "")
                            
                {
                    $pathinfo= [pscustomobject]@{
                        ACTION=$sp[0]
                        PATH=$sp[1]
                    }
                    $paths+=$pathinfo
                    $action=$pathinfo.ACTION
                    $action='"'+$action+'"'
                    $file='"'+"file"+'"'
                    $path=$pathinfo.PATH
                    $stream.WriteLine("<path   action=$ACTION   kind=$file>$PATH</path>")
                }
            }
            $test+=$paths
        }
        $msg=$tags[1]
        $stream.WriteLine("</paths>")
        $stream.WriteLine("<msg>$msg</msg>")
        $stream.WriteLine("</logentry>")
    }
}

$stream.WriteLine('</log>')
$stream.close()

(gc .\t.txt) -Replace '&','&amp;' | Set-Content output.xml
remove-item t.txt 
}


function gen_out_file ()
{
    [xml]$varaible1 = Get-Content output.xml 
    
    $count=0
    
    ForEach ($_ in $varaible1.log.logentry)
    {
        ForEach ($b in $_.paths.path)
        {
            if ($b.kind -eq "file" -and $b.action -ne "D" )
            {
                ForEach ($a in $b."#text") 
                {
                    $upper = $a.Split("/").GetUpperBound(0)
                    
                    $last = $a.Split("/")[$upper]
                    
                    $out=  $_.Date+","+$a+","+$_.msg+","+$_.revision | Out-File out.lst -NoClobber -Append -Encoding ASCII 
                    
                }
            }
        }
    }
}
function find_max ($type,$file1)
{
"Finding Max of Jiras $(Date) " >>logs.txt
    $searched = Get-Content out.lst
    
    $ouput=$null
    $file = import-csv $file1
    
    # Create Jira and workflow list
    
    foreach ( $rec in $searched ) 
    {
        
        $loc_jira =   $rec.Split(",")[1] + "," +  $rec.Split(",")[2] 
        
        $loc_jira | Out-File LOC_JIRA.lst -NoClobber -Append -Encoding ASCII 
        
    }
    $unique = Get-Content LOC_JIRA.lst | sort -Unique
    
    # Find if 2 jiras have the same workflow
    $locs = @()
    
    foreach ($record in $unique)
    {
        $locs += $record.Split(",")[0]
        
    }
    
    $unique_loc = $locs | sort -unique
    
    
    if ( $unique_loc.Count -ne $locs.Count )
    {
        #Write-Host "1 Workflow has 2 Jira Number Picking Highest Revision " -ForegroundColor Red
        # return -1 # if you dont want to execute the import for this scenario
    }
    
    
    
    # get the highest value of rev_no for each mapping
    
    $loco=ConvertFrom-csv -InputObject $unique -Delimiter "," -Header path , jira ,sha
    $desktop1 = GET-LOCATION
    
    $desktop=$desktop1.Path
    
    $folder_list = @()
    
    
    foreach ($itr in $loco)
    {
        $max=[datetime]::parse('1990-12-19T16:55:56+05:30')
        
        $picked_jira=""
        
        foreach ($itr1 in $searched)
        {
            if( $itr.path -eq   $itr1.Split(",")[1] )
            {
                if ($max -lt [datetime]::parse($itr1.Split(",")[0]) )  
                {
                    $max = [datetime]::parse($itr1.Split(",")[0])
                    
                    $picked_jira=$itr1.Split(",")[2]
                    $ps_output = $itr.path.split('/')[-2] + "," + $itr.path.split('/')[-1] + "," + $itr1.Split(",")[2] + "," + $itr1.Split(",")[3] + "," + $itr1.Split(",")[0]
                    $sha= $itr1.Split(",")[3]
                    
                }
            } 
        }
        write-output "here"
        $array_num=[array]::indexof($file.filename,$itr.path.split('/')[-1])
        if ($array_num -ne -1 )
        {
            $file[$array_num].found="Yes"
        }
        #$ouput = "svn export -r "+ $max + " " + $itr.path.split('/')[-2] +"\"+ $itr.path.split('/')[-1] + " """ + $desktop +"\AUTOMATIC_DG\"+$itr.path.split('/')[-2] +"\"+ $itr.path.split('/')[-1] + """"
        #$ouput=$picked_jira+","+$itr.jira+","+$max+","+$itr.path.split('/')[-2]+","+$itr.path.split('/')[-1]+","+$type + "," + $itr.sha
        $ouput = "git checkout" + " " + $sha + " " + $itr.path + ";" + "start-sleep -Milliseconds 500 ;"
        
        echo $ouput| Out-File svn_export.lst -NoClobber -Append -Encoding ASCII 
        
        
        #echo $ouput;
        $folder_list += $itr.path.split('/')[-2]
        
        
        
        echo $ps_output | Out-File PS_OUTPUT.lst -NoClobber -Append -Encoding ASCII 
        
    }
    
    
    $file | Export-Csv $file1 -NoTypeInformation
    $uniquesvn = get-content svn_export.lst | sort | Get-Unique
    echo $uniquesvn | Out-File svn_export.lst -Encoding ASCII 
    
    (Import-Csv .\PS_OUTPUT.lst -Header folder,xml,jira,rev,date | sort date |select folder,xml,jira,rev,date | ConvertTo-Csv -NoTypeInformation | Select-Object  -Skip 1).replace('"','') | Out-File PS_OUTPUT.lst -Encoding ASCII
    $uniquePsoutput = get-content PS_OUTPUT.lst | Get-Unique
    echo $uniquePsoutput | Out-File PS_OUTPUT.lst -Encoding ASCII 
    
    $folder_list_uniq = $folder_list | sort -unique
    
    foreach ($folder in $folder_list_uniq) {
$path =  $cwd +"\AUTOMATIC_DG\"+$folder ;

    If(!(test-path $path))
    {
          New-Item -ItemType Directory -Force -Path $path
    }
}
 
  #  DEL LOC_JIRA.lst -ErrorAction SilentlyContinue
}

# ================================ Logic for SVN Check =======================================
function comment_check ($path,$type,$file)
{
"Checking Comments for Jiras $(Date) " >>Timestamps.txt
	$cwd = get-location
	getlog $path
	cd $cwd.path
    #svn log -v  $path --xml  > output.xml
    #pause
    [xml]$result = gc .\Build_Automation_Central\output.xml
 
   
    $cwd = $cwd.Path
    $deletemerge = $result.log.logentry | foreach {if (($_.msg -like 'Merge*') -or ($_.paths.path.action | Sort-Object -Unique | Out-String).replace("`r`n",'') -notmatch "^A$|^D$|^M$|^AM$") { $_ } }
    
    foreach ($entry in $deletemerge){ 
        $result.log.RemoveChild($entry)
    }
    
    $result.Save("$cwd\output.xml")
    [Xml] $vars =  Get-Content output.xml
    
    
    $deletelogentry = @()
    "Date,Path" | Out-File todel.csv -Append -Encoding utf8
    
    foreach($logentry in $vars.log.logentry) {
        foreach($path in $logentry.paths.path) {
            if ($path.action -eq "D") {
                if (-Not($deletelogentry -Contains $logentry)) {
                    $deletelogentry += $logentry
                }
                $logentry.Date + "," + $path.'#text' | Out-File todel.csv -Append -Encoding utf8
                
            }
        }
    }
	
    $csv = Import-CSV "todel.csv"
    
    ForEach($obj in $vars) {
        foreach($log in $obj.log) {
            foreach($logentry in $log.logentry) {
                foreach($date in $logentry.date) {
                    foreach($line in $csv) {
                        if ([datetime]::parse($date) -lt [datetime]::parse($line.date))
                        {
                            foreach($logpath in $logentry.paths.path) {
                                if ($Line.Path -eq $logpath.'#text') {
                                    if (-Not($deletelogentry -Contains $logentry)) {
                                        $deletelogentry += $logentry
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    
    foreach ($entry in $deletelogentry){ 
        $vars.log.RemoveChild($entry)  >>$null 2>>$null
    }
    
    ForEach($obj in $vars) {
        foreach($log in $obj.log) {
            foreach($logentry in $log.logentry) {
                $logentry.msg = ($logentry.msg).Split("`n")[0] -replace "_", "-"
            }
        }
    }
    
    
    $deletelogentry = @()
    $jiras = Get-Content .\input*
    
    ForEach($obj in $vars) {
        foreach($log in $obj.log) {
            foreach($logentry in $log.logentry) {
                if (-not($jiraS -Contains $logentry.msg)) {
                    write-output "$logentry.msg"
                    $deletelogentry += $logentry
                }
            }
        }
    }
    
    foreach ($entry in $deletelogentry){ 
        $vars.log.RemoveChild($entry)
    }
    
    $vars.Save("$cwd\output.xml")
	
	$UNIQUE = @()
    if ( Test-Path "$cwd\todel.csv" ) {  Remove-Item -path "$cwd\todel.csv"   -Recurse -Force  }
    [Xml] $etl =  Get-Content output.xml
    $fusedlist = $etl.log.logentry |Select-Object @(@{l="jira"
        e={$_.msg}},@{l="INFA"
        e={"YES"}}) 
    $UNIQUE = $fusedlist | Sort-Object -Property jira -Unique | foreach{IF($_.jira -like 'IHUBBAU*') {$_} }
  #  cd .\Build_Automation_Central
    gen_out_file
    find_max $type $file
    
}

"Working on Autosys $(Date) " >>Timestamps.txt
$ETL_LIST=comment_check $SVN_ETL_LOCATION "Autosys" 

$ouput = gc .\svn_export.lst

cd .\Build_Automation_Central
foreach ($line in $ouput)
{ Invoke-Expression $line ; $line.split("/")[-1] +" "+ $LASTEXITCODE |out-file Invokelog.txt -Append}
$invoke_log = gc .\Invokelog.txt
Get-ChildItem -Path .\Autosys -recurse -File | % {echo $_.FullName} | out-file list_of_xml.txt
$list_of_xml = gc .\list_of_xml.txt


remove-item .\Invokelog.txt
Remove-Item .\list_of_xml.txt
cd $cwd
$invoke_log | out-file Invokelog.txt
$list_of_xml | out-file list_of_xml.txt
$automatic_dg_loc = ".\AUTOMATIC_DG"
foreach ($xmlfilelocation in $list_of_xml)
{$xmlfilelocationsplit = $xmlfilelocation.Split("\")[-2] ; Copy-Item $xmlfilelocation -Destination "$automatic_dg_loc\$xmlfilelocationsplit"}
"Working on Autosys Complete $(Date) " >>Timestamps.txt