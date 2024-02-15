# Get grading directory
gradingDir="/home/ro99/Grading/netidsRepo"
paName="pa2-dstruct"
submissionTag=$paName-submission

mkdir clangResults
clangDir=$(pwd)/clangResults

# Get netid list
netids=$( cat ../admin/ece2400-netids.txt )

paReleaseDir=/home/ro99/Grading/ece2400-pa-release/$paName

srcFiles=$( ls $paReleaseDir/src )
testFiles=$( ls $paReleaseDir/test  )

countComments() {
  # $1 is destination folder
  cd $1
  count=0
  
  files=$( ls )
  for file in $files
    # Check all the original files in source and test folders only
    do if [[ $file != "."  && ( $srcFiles == *"$file"* ||  $testFiles == *"$file"* ) ]]
    then 
      commentCount=$( grep -o "//" $file | wc -l )
      count=$(( $count + $commentCount ))
    fi 
  done
}

# Function for finding number of changes after clang-format
gitClang () {
  # $1 is netid, $2 is destination folder
  dest=$gradingDir/$1/$paName/$2
  cd $dest
  files=$( find . )

  # Reset counters for exectuable and core files
  if [ $2 == src ]
  then
    otherFiles=0
  fi

  for file in $files
    # Check if file is executable
    do if [[ $file == *".c" ]] || [[ $file == *".h" ]]
      then 
        clang-format -i "$file"
    elif [[ $file != "." ]]
      then (( otherFiles+=1 ))
    fi
  done

  # Get last line of stat summary that contains num of files changed, lines inserted, and lines deleted
  stats=$( git diff --stat --summary | tail -1 )

  # If stats is null
  if [ -z "$stats" ]
    then stats="0,0,0,"
  else
    # Extract the numbers and delimit with commas
    stats=$( echo $stats |  tr -dc '0-9 ' | tr -s '[:blank:]' ',')
  fi

  # Reset clang-format changes
  git reset --hard
}

# Git clone all student directories 
for netid in $netids
  # If netid is not in gradingDir
  do if [ ! -d $gradingDir/$netid ]
  then
    git clone git@github.com:cornell-ece2400/"$netid".git $gradingDir/$netid
    cd $gradingDir/$netid
    git checkout $submissionTag
  else 
    cd $gradingDir/$netid

    # Reset all changes made previously
    git reset --hard
  fi
done

# Check clang formatting & count comments

countComments $paReleaseDir/src
# Original counts are based on the number of comments with "Assignment Task" deleted
origSourceCount=$count

countComments $paReleaseDir/test
origTestCount=$count

echo "Netid,Source File Changed,Source Lines Inserted,Source Lines Deleted,\
Test Files Changed,Test Lines Inserted,Test Lines Deleted,Other Files Count,Source Comments Count, Test Comments Count"\
> $clangDir/ece2400-$paName-clang.csv

for netid in $netids
  do
    gitClang $netid src
    results=$stats

    gitClang $netid test
    results="$results$stats"

    countComments $gradingDir/$netid/$paName/src
    sourceCount=$(( $count - $origSourceCount ))
    
    countComments $gradingDir/$netid/$paName/test
    testCount=$(( $count - $origTestCount ))
    
    echo "$netid,$results$otherFiles,$sourceCount,$testCount" >> $clangDir/ece2400-$paName-clang.csv
done