 Cron job runs every 30 minutes: 0,30 * * * * /usr/local/awscheck/instancecheck.sh
cd /usr/local/awscheck
EMAIL="zorang@email.com"
aws ec2 describe-instances | jq -r  '.Reservations[].Instances[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.InstanceId)#\(.InstanceType)#\(.PrivateIpAddress)#\(.PublicIpAddress)#\(.PublicDnsName)#\(.State.Name)#\(.Platform)#\(.LaunchTime)#\(.VpcId)#\(.SubnetId)#\(.Placement.AvailabilityZone)#\(.KeyName)#\(.ImageId)#\(.Monitoring.State)#\(.BlockDeviceMappings[0].Ebs.VolumeId)#\(.BlockDeviceMappings[1].Ebs.VolumeId)#\(.BlockDeviceMappings[2].Ebs.VolumeId)#\(.BlockDeviceMappings[3].Ebs.VolumeId)#\(.BlockDeviceMappings[4].Ebs.VolumeId)#\(.BlockDeviceMappings[5].Ebs.VolumeId)#\(.BlockDeviceMappings[6].Ebs.VolumeId)#\(.BlockDeviceMappings[7].Ebs.VolumeId)#\(.BlockDeviceMappings[8].Ebs.VolumeId)#\(.BlockDeviceMappings[9].Ebs.VolumeId)#\(.SecurityGroups[0].GroupId)#\(.SecurityGroups[1].GroupId)#\(.SecurityGroups[2].GroupId)#\(.SecurityGroups[3].GroupId)#\(.SecurityGroups[4].GroupId)#\($tags.Name)#\($tags.Product)#\($tags.Bu)#\($tags.Environment)#\($tags.Owner)#\($tags.Cc)#\($tags.Capacity)#\($tags["aws:cloudformation:stack-name"])"'  2>/dev/null |  tr ',' ';' | tr '#' ',' | sed "1,\$s/^/$i,/" | grep -v terminated > instances

echo -e "Instance-id Days-since-creation Username PrincipalID\n" > email
cat instances | cut -d',' -f1-2,31-38 | grep 'null,null,null,null,null,' > untaggedinst
for inst in `cat untaggedinst | cut -d',' -f2 `
do
    si=`grep $inst instances | cut -d',' -f9`
    secs=`expr $(date +%s) - $(date -d "$si" +%s)`
    days=$(echo "scale=5;$secs/86400" | bc)
    aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=$inst | grep $inst |  head -1  | tr ',' '\n' > cloudtrail
    user=$(grep -i 'username' cloudtrail |  cut -d'"' -f4 | cut -d'\' -f1)
    principal=$(grep -i 'principalId' cloudtrail | head -1 |  cut -d'"' -f4 | cut -d'\' -f1)
    sleep 2
    echo "$inst $days $user $principal"
done | sort -n -k 2 | awk ' { if ($2 <= 0.02083) print $0 } ' >> email

[ -s email ] && cat email | mail -v -s "Untagged instances created in last 30 minutes" $EMAIL
