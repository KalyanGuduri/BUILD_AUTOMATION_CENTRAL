$searched = Get-Content out.lst;
$AppProps = convertfrom-stringdata (get-content ./properties.txt -raw)
$Upload_folder = $AppProps.'app.package_name'


# Create Jira and workflow list

foreach ( $rec in $searched ) {

$loc_jira =   $rec.Split(",")[1] + "," +  $rec.Split(",")[2] ; 
$loc_jira | Out-File LOC_JIRA.lst -NoClobber -Append -Encoding ASCII ; 

}


$unique = Get-Content LOC_JIRA.lst | sort -Unique


# Find if 2 jiras have the same workflow

$locs = @();
foreach ($record in $unique)
{
 
 $locs += $record.Split(",")[0];

}

$unique_loc = $locs | sort -unique;
#echo $unique_loc;

if ( $unique_loc.Count -ne $locs.Count )
{
 Write-Host "1 Workflow has 2 Jira Number Picking Highest Revision " -ForegroundColor Red
 # return -1 # if you dont want to execute the import for this scenario
}



# get the highest value of rev_no for each mapping

# $desktop = [Environment]::GetFolderPath("Desktop");
$desktop1 = GET-LOCATION;
$desktop=$desktop1.Path;
$folder_list = @();

foreach ($itr in $locs)
{
 $max=0; 

  foreach ($itr1 in $searched)
  {
    if( $itr -eq   $itr1.Split(",")[1] )
    {
      if ([int]$max -lt [int]$itr1.Split(",")[0] )  
      {
         $max = $itr1.Split(",")[0];
         $ps_output = $itr.split('/')[-2] + "," + $itr.split('/')[-1] + "," + $itr1.Split(",")[2] ;
      }
    }
  }

  $ouput = "svn export -r "+ $max + " " + $itr.split('/')[-2] +"\"+ $itr.split('/')[-1] + " """ + $desktop +"\$Upload_folder" + """";
  echo $ouput| Out-File svn_export.lst -NoClobber -Append -Encoding ASCII ;
  
  #echo $ouput;
  $folder_list += $itr.split('/')[-2];

  
  echo $ps_output | Out-File PS_OUTPUT.lst -NoClobber -Append -Encoding ASCII ;
}

$uniquesvn = get-content svn_export.lst | sort | Get-Unique
echo $uniquesvn | Out-File svn_export.lst -Encoding ASCII 

$uniquePsoutput = get-content PS_OUTPUT.lst | sort | Get-Unique
echo $uniquePsoutput | Out-File PS_OUTPUT.lst -Encoding ASCII 

$folder_list_uniq = $folder_list | sort -unique;

#echo $folder_list_uniq;


#foreach ($folder in $folder_list_uniq) {
#$path =  $desktop +"\AUTOMATIC_AUTOSYS\"+$folder ;

#    If(!(test-path $path))
#    {
#          New-Item -ItemType Directory -Force -Path $path
#    }
#}

DEL LOC_JIRA.lst
