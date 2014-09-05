#!/bin/bash

# Shell script for processing courlistener bulk exports without decompressing them or putting the entire file in memory
#
# Usage:
#  $ ./courtlistener_process.sh all.xml.gz
#  $ ./courtlistener_process.sh scotus.xml.gz
# * param1: Compressed Courtlistener bulk data file

bulkfile="$*"
filesize=$(du -h $bulkfile)
echo "File Info: $filesize"
echo "Reading file, please wait because this might take a while......"
opinions=$(gzip -dc $bulkfile | grep -c "<opinion ")
processed=0
echo "Processing $opinions opinions from Court Listener File : $bulkfile"


readkey () {
  key="$1"
  echo $ATTRIBUTES | awk "match(\$0, /${key}=\"([^\"]+)\"/) { print substr( \$0, RSTART, RLENGTH )}" | sed -e 's/.*="\(.*\)"/\1/g'
}
read_node () {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local ret=$?
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $ret
}

to_json () {
    if [[ $TAG_NAME = "opinion" ]] ; then
        id=$(readkey 'id')
        path=$(readkey 'path')
        sha1=$(readkey 'sha1')
        court=$(readkey 'court')
        time_retrieved=$(readkey 'time_retrieved')
        date_filed=$(readkey 'date_filed')
        precedential_status=$(readkey 'precedential_status')
        federal_cite_one=$(readkey 'federal_cite_one')
        case_name=$(readkey 'case_name')
        judges=$(readkey 'id')
        nature_of_suit=$(readkey 'nature_of_suit')
        source_=$(readkey 'source')
        blocked=$(readkey 'blocked')
        date_blocked=$(readkey 'date_blocked')
        cited_by=$(readkey 'cited_by')

        JSON="{"

          JSON+="path:\"$path\","
          JSON+="sha1:\"$sha1\","
          JSON+="court:\"$court\","
          JSON+="time_retrieved:\"$time_retrieved\","
          JSON+="date_filed:\"$date_filed\","
          JSON+="precedential_status:\"$precedential_status\","
          JSON+="federal_cite_one:\"$federal_cite_one\","
          JSON+="case_name:\"$case_name\","
          JSON+="judges:\"$judges\","
          JSON+="nature_of_suit:\"$nature_of_suit\","
          JSON+="source:\"$source_\","
          JSON+="blocked:\"$blocked\","
          JSON+="date_blocked:\"$date_blocked\","
          JSON+="cited_by:[$cited_by]"
          JSON+="content:$CONTENT" ##Some content seems to have html. Not sure what bash can do about that

        JSON+="}"

        processed=$((processed+1))

        if [ $processed -lt 3 ] ; then
         echo "Sample Output:"
         echo $JSON
        fi
        echo -ne "Procesing:  $((100*$processed/$opinions))% \r"
    fi
}

gzip -dc $bulkfile | while read_node; do
    to_json
done

echo "Finished!!"
