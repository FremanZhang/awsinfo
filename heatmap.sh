#!/bin/bash
basedir=/home/ec2-user/awsinfo
accounts="ndm dpprod nlmprod dsprod opsdev diguat salesuat salesdev finprod nlmburo newsapi aibmuat aibmdev dsuat aibmprod anildoma dpuat nlmdev salesprod digdev dsdev nlmuat findev finuat dpdev"
instances="t2.micro t1.micro t2.small m1.small t2.medium m3.medium m1.medium c3.large c4.large t2.large c1.medium m4.large m3.large r3.large m1.large c3.xlarge c4.xlarge m2.xlarge m4.xlarge m3.xlarge r3.xlarge m1.xlarge c3.2xlarge c4.2xlarge m2.2xlarge c1.xlarge m4.2xlarge m3.2xlarge r3.2xlarge d2.xlarge g2.2xlarge i2.xlarge c3.4xlarge c4.4xlarge m2.4xlarge m4.4xlarge r3.4xlarge d2.2xlarge i2.2xlarge c3.8xlarge c4.8xlarge r3.8xlarge d2.4xlarge m4.10xlarge g2.8xlarge i2.4xlarge hs1.8xlarge d2.8xlarge i2.8xlarge"

cd $basedir
> temp.instances.hourly
# For each AWS account gather AWS information
for i in $accounts
do
  echo "Account = $i"
  export AWS_DEFAULT_PROFILE=$i
  aws ec2 describe-instances | jq -r  '.Reservations[].Instances[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.InstanceId),\(.InstanceType),\(.PrivateIpAddress),\(.PublicIpAddress),\(.PublicDnsName),\(.State.Name),\(.Platform),\(.LaunchTime),\(.VpcId),\(.SubnetId),\(.Placement.AvailabilityZone),\(.KeyName),\(.ImageId),\(.Monitoring.State),\(.BlockDeviceMappings[0].Ebs.VolumeId),\(.BlockDeviceMappings[1].Ebs.VolumeId),\(.BlockDeviceMappings[2].Ebs.VolumeId),\(.BlockDeviceMappings[3].Ebs.VolumeId),\(.BlockDeviceMappings[4].Ebs.VolumeId),\(.BlockDeviceMappings[5].Ebs.VolumeId),\(.BlockDeviceMappings[6].Ebs.VolumeId),\(.BlockDeviceMappings[7].Ebs.VolumeId),\(.BlockDeviceMappings[8].Ebs.VolumeId),\(.BlockDeviceMappings[9].Ebs.VolumeId),\(.SecurityGroups[0].GroupId),\(.SecurityGroups[1].GroupId),\(.SecurityGroups[2].GroupId),\(.SecurityGroups[3].GroupId),\(.SecurityGroups[4].GroupId),\($tags.Name),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc),\($tags.Capacity),\($tags["aws:cloudformation:stack-name"])"'  2>/dev/null | sed "1,\$s/^/$i,/" >> temp.instances.hourly
  wc -l temp.instances.hourly
done

(
cat temp.instances.hourly | while read line
do
  a=`echo $line | cut -d',' -f1`
  c=`echo $line | cut -d',' -f2`
  s=`echo $line | cut -d',' -f7`
  export AWS_DEFAULT_PROFILE=$a
  cpuavg=$(aws cloudwatch get-metric-statistics --metric-name CPUUtilization --start-time `date -u --date="1 hour ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date -u +'%Y-%m-%dT%H:%M:00'` --period 3600 --namespace AWS/EC2 --statistics Average --dimensions Name=InstanceId,Value=$c  | grep "Average" | cut -d':' -f2 | cut -d',' -f1)
   [ "$cpuavg" == "" ] && cpuavg=0
  
  echo "$line,$cpuavg" 
done
) > temp.instances.hourly.new
mv temp.instances.hourly.new temp.instances.hourly


h=`date +%H`
if [ $h -eq 0 ]
then
(
    for i in $instances
    do 
       echo "$i"
    done
) > instancesummary
cp instancesummary instancecost
cp instancesummary instanceperf
fi

(
for i in $instances
do 
   line=`grep $i instancesummary`
   total=`cat temp.instances.hourly | grep -c "$i"`
   running=`cat temp.instances.hourly | grep running | grep -c "$i"`
   linuxaza=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,null,ap-southeast-2a"`
   linuxazb=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,null,ap-southeast-2b"`
   windowsza=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,windows,ap-southeast-2a"`
   windowszb=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,windows,ap-southeast-2b"`
   
   echo "$i,$total,$running,$linuxaza,$linuxazb,$windowsza,$windowszb"
done
) > instances.hourly.$h

> instancesummary.new
> instancecost.new
> instanceperf.new
for i in $instances
do 
   line=`grep $i instancesummary`
   linecost=`grep $i instancecost`
   lineperf=`grep $i instanceperf`
   total=`cat temp.instances.hourly | grep -c "$i"`
   running=`cat temp.instances.hourly | grep running | grep -c "$i"`
   linuxaza=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,null,ap-southeast-2a"`
   linuxazb=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,null,ap-southeast-2b"`
   windowsza=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,windows,ap-southeast-2a"`
   windowszb=`cat temp.instances.hourly | grep running | cut -d',' -f3,8,12 | grep -c "$i,windows,ap-southeast-2b"`
   linuxcost=`grep $i aws.costs | grep ec2 | cut -d',' -f5`
   windowscost=`grep $i aws.costs | grep ec2 | cut -d',' -f6`
   totallinux=`expr $linuxaza + $linuxazb`
   totalwindows=`expr $windowsza + $windowszb`
   cost=$(echo "scale=2;($linuxcost*$totallinux/720)+($windowscost*$totalwindows/720)" | bc)

   if [ $running -ne 0 ]
   then
      totalcpu=$(grep $i temp.instances.hourly | grep running | cut -d',' -f39 | awk ' { x+=$1; print x } ' | tail -1)
      avgcpu=$(echo "scale=2;$totalcpu/$running" | bc )
   else
      avgcpu=0
   fi
   echo "$i $avgcpu"
   
   #echo "$line,$total,$running,$linuxaza,$linuxazb,$windowsza,$windowszb"
   echo "$line,$running" >> instancesummary.new
   echo "$linecost,$cost" >> instancecost.new
   echo "$lineperf,$cost" >> instanceperf.new
done
mv instancesummary.new instancesummary
mv instancecost.new instancecost
mv instanceperf.new instanceperf


if [ $h -eq 23 ]
then
   (
    echo ",0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23"
    cat instancesummary
   ) >  heatmap
   (
    echo ",0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23"
    cat instancecost
   ) >  heatmap.cost
   (
    echo ",0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23"
    cat instanceperf
   ) >  heatmap.perf

fi

