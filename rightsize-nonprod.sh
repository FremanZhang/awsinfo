while read line; do
   i=`echo $line | cut -d',' -f2`
   t=`echo $line | cut -d',' -f3`
   tp=`echo $line | cut -d',' -f54 | cut -d'-' -f1`
   e=`echo $line | cut -d',' -f34`

   echo $e | grep -i prod > /dev/null
   prod=$?

   if [ $prod -ne 0 ] && [ "$tp" != "" ]
   then
        echo "#$line"
        echo "echo change-instancetype.sh $i $tp | at 1:00 AM September 20 2015" 
        echo
   fi
done < instances
