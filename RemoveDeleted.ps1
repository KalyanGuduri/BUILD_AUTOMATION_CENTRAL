[xml]$result = gc .\output.xml
$deletemerge=@()
$cwd = get-location
$cwd = $cwd.Path
$deletemerge = $result.log.logentry | foreach {if (($_.msg -like 'Merge*') -or ($_.paths.path.action | Sort-Object -Unique | Out-String).replace("`r`n",'') -notmatch "^A$|^D$|^M$|^AM$") { $_ } }

foreach ($entry in $deletemerge)
{ 
$result.log.RemoveChild($entry)
}

$result.Save("$cwd\output.xml")
[Xml] $vars =  Get-Content output.xml
$deletelogentry = @()
 "Revision,Path" | Out-File todel.csv -Append -Encoding utf8
ForEach ($obj in $vars)
{
foreach ( $log in  $obj.log)
{
    foreach ($logentry in $log.logentry)
    {
        foreach ($path in $logentry.paths.path)
        {
            if ($path.action -eq "D" )
            {
              if ( -Not ($deletelogentry -Contains $logentry ))
                            {
                $deletelogentry+=$logentry
                }
                $logentry.revision+","+$path.'#text' | Out-File todel.csv -Append -Encoding utf8
                 
            }
        }
    }
}
}





$csv = Import-CSV "todel.csv"



ForEach ($obj in $vars)
{
foreach ( $log in  $obj.log)
{
    foreach ($logentry in $log.logentry)
    {

         foreach ($revision in $logentry.revision)
         {
         
        foreach ($line in $csv)
        {
            if ($revision -lt $line.Revision)
           
            {
            
                foreach ($logpath in $logentry.paths.path)
                {
                   
                        if ( $Line.Path -eq $logpath.'#text')
                        {
                            if ( -Not ($deletelogentry -contains $logentry ))
                            {
                            $deletelogentry+=$logentry
                             
                            }
                           
                            
                        }
                    
                }
            }
           }
        }
    }
}
}


foreach ($entry in $deletelogentry)
{ 
$vars.log.RemoveChild($entry) >  $null
}




ForEach ($obj in $vars)
{
foreach ( $log in  $obj.log)
{
    foreach ($logentry in $log.logentry)
    {
      
          $logentry.msg = ($logentry.msg).Split("`n")[0] -replace "_" , "-"
         
    }
}
}


$deletelogentry = @()
$jiras = Get-Content "Jira.csv"

ForEach ($obj in $vars)
{
foreach ( $log in  $obj.log)
{
    foreach ($logentry in $log.logentry)
    {
        
           if (-not ($jiraS -Contains $logentry.msg) )
           {
           
              $deletelogentry+=$logentry
           }
         
    }
}
}


foreach ($entry in $deletelogentry)
{ 
$vars.log.RemoveChild($entry) > $null
}






$vars.Save("$cwd\output.xml")

#to do delete todel
if ( Test-Path "$cwd\todel.csv" ) {  Remove-Item -path "$cwd\todel.csv"   -Recurse -Force  }