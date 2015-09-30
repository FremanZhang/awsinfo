# Cron job runs every 5 minutes: */5 * * * * /usr/local/awscheck/volumecheck.sh
rundaily=0600

daily ()
{
# create list of currently unattched volumes
aws ec2 describe-volumes | jq -r  '.Volumes[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.VolumeId),\(.VolumeType),\(.Encrypted),\(.State),\(.Size),\(.Attachments[0].InstanceId),\(.Attachments[0].State),\(.Attachments[0].DeleteOnTermination),\(.Attachments[0].Device),\($tags.Name),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc)"' 2>/dev/null   | awk -F',' ' { print $1 " " $6 } ' | grep -v i- | cut -d' '  -f1 > unattached

# check volumes on unattented.old "watch list" and increment number of days unattached, send out email to Wintel/Unix teams if unattached volume is found
> unattached.new
for i in `cat unattached`
do
  line=`grep $i unattached.old `
  x=$?
  if [ $x -eq 0 ]
  then
    vol=`echo $line | cut -d' ' -f1`
    days=`echo $line | cut -d' ' -f2`
    echo "$vol `expr $days + 1`"
    user=` aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=CreateVolume --max-results 50 2>/dev/null | grep $vol  | head -1  | tr ',' '\n' | grep -i username | cut -d'"' -f4 | cut -d'\' -f1`
    echo "Volume $vol has been unattached to instance for $days days, created by $user" | mailx -s "Unattached volumes" supportdesk@company.com
  else
    echo "$i 1" >> unattached.new
  fi
done > unattached.temp
cat unattached.temp unattached.new > unattached.old

# Delete volume with more than 30 day unattached
for i in `cat unattached.old`
do
  line=`grep $i unattached.old `
  vol=`echo $line | cut -d' ' -f1`
  days=`echo $line | cut -d' ' -f2`
  if [ $days -gt 30 ]
  then
      echo "Delete volumes after 30 days unattached: ec2 delete-volume --volume-id $vol"
  fi
done
}

every5mins ()
{
# check if untagged volumes exists, if so delete them
for vol in `aws ec2 describe-volumes | jq -r  '.Volumes[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.VolumeId),\(.VolumeType),\(.Encrypted),\(.State),\(.Size),\(.Attachments[0].InstanceId),\(.Attachments[0].State),\(.Attachments[0].DeleteOnTermination),\(.Attachments[0].Device),\($tags.Name),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc)"' 2>/dev/null  | awk -F',' ' { print $1 "," $10 "," $11 "," $12 ","  $13 "," $14 "," $15 } ' | grep 'null,null,null,null,null,null' | cut -d',' -f1`; do echo "Delete untagged volumes: ec2 delete-volume --volume-id $vol"; done

# check whether volumes on "watch list" of unattached volumes were attached to instances, in which case remove them from "watch list"
> unattached.temp
for i in `cat unattached`
do
  grep $i unattached.old >> unattached.temp
done
mv unattached.temp unattached.old
}

# Main
hr=`date +%H`
min=`date +%M`
if [ "$hr$min" == "$rundaily" ]
then
   daily
else
   every5mins
fi
