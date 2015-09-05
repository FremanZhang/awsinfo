#!/bin/bash
# awsinfo.sh - Produces Excel spreadsheet about AWS resources
#
# Zoran Gagic - zorang at gmail.com
#
# Copyright (C) 2015  Zoran Gagic

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA

# 0 11 * * * /usr/local/awsinfo/awsinfo.sh > /usr/local/awsinfo/awsinfo.out 2>&1

basedir=/usr/local/awsinfo
accounts="acct1 acct2 acct3 acct4 acct5 acct6"
s3bucket=mys3bucket

headers ()
{
echo "Account,InstanceId,InstanceType,PrivateIpAddress,PublicIpAddress,PublicDnsName,State,Platform,LaunchTime,VpcId,SubnetId,AvailabilityZone,KeyName,ImageId,Monitoring,Volume 1, Volume 2, Volume3, Volume 4, Volume 5,Volume 6,Volume 7,Volume 8,Valume 9,Valume 10,SG 1,SG 2,SG 3,SG 4,SG 5,Tag Name,Tag Product,Tag BU,Tag Environment,Tag Owner,Tag CC,Total Size all EBS Volumes,CPU 95th Percentile (when running),Instance CPU cores/memory,Percent Running,Monthly Cost,EBS Monthly Cost,Snapshot Monthly Cost,Days since Launch,Duration since Launch,Running at Night,DiskReadBytes95,DiskWriteOps95,DiskReadOps95,DiskWriteOps95,NetworkIn95,NetworkOut95" > instances
echo "Account,VolumeId,VolumeType,Encrypted,State,Size,InstanceId,State,DeleteOnTermination,Device,Tag Name,Tag Product,Tag Bu,Tag Environment,Tag Owner,Tag Cc,Monthly Cost,VolumeIdleTime95,VolumeQueueLength95,VolumeReadBytes95,VolumeWriteBytes95,VolumeReadOps95,VolumeWriteOps95" > volumes
echo "Account,ImageId,CreationDate,VirtualizationType,Name,VolumeSize,Architecture,Public,Tag Name,Tag Product,Tag Bu,Tag Environment,Tag Owner,Tag Cc,Monthly Cost" > images
echo "Account,.SnapshotId,StartTime,VolumeSize,Description,VolumeId,State,Progress,Encrypted,Tag Product,Tag Bu,Tag Environment,Tag Owner,Tag Cc,Tag Name,Monthly Cost" > snapshots
echo "Account,VpcId,CidrBlock,DhcpOptionsId,DhcpOptionsId,IsDefault,Tag Product,Tag Bu,Tag Environment,Tag Owner,Tag Cc" > VPCs
echo "Account,VpcId,SubnetId,AvailabilityZone,CidrBlock,AvailableIpAddressCount,Tag Product,Tag BusinessUnit,Tag Environment,Tag Owner,Tag CostCenter" > subnets
echo "Account,.RouteTableId,VpcId,Associations[0].Main,Associations[0].SubnetId,Associations[1].SubnetId,Associations[2].SubnetId,Associations[3].SubnetId,Associations[4].SubnetId,Associations[5].SubnetId,.Associations[6].SubnetId,Associations[7].SubnetId,Associations[8].SubnetId,Associations[9].SubnetId,Routes[0].DestinationCidrBlock,Routes[1].DestinationCidrBlock,Routes[2].DestinationCidrBlock,Routes[3].DestinationCidrBlock,Routes[4].DestinationCidrBlock,Routes[5].DestinationCidrBlock,Routes[6].DestinationCidrBlock,Routes[7].DestinationCidrBlock,Routes[8].DestinationCidrBlock,Routes[9].DestinationCidrBlock,Tags Product,Tags BusinessUnit,Tags Environment,Tags Owner,Tags CostCenter,Tags Name" > routetables
echo "Account,LoadBalancerName,DNSName,CreatedTime,VPCId,Subnets[0],Subnets[1],Listener.InstancePort,Listener.LoadBalancerPort,Listener.Protocol,Listener.InstanceProtocol,Instances[0],Instances[1],Instances[2],Instances[3],HealthCheck.HealthyThreshold,HealthCheck.Interval,HealthCheck.Target,HealthCheck.Timeout,HealthCheck.UnhealthyThreshold,Tags Product,Tags Bu,Tags Environment,Tags Owner,Tags Cc,Tags Name" > ELBs
echo "Account,DBInstanceIdentifier,Engine,DBSubnetGroup.VpcId,AvailabilityZone,MultiAZ,DBInstanceClass,StorageType,AllocatedStorage,InstanceCreateTime,Tags Product,Tags BusinessUnit,Tags Environment,Tags Owner,Tags CostCenter,CPU 95th Percentile (when running),Percent Running,Monthly Cost" > RDS
> IAM
echo "Account,Bucket,Size,Monthly Cost" > S3
echo "Account,CacheClusterId,Engine,NumCacheNodes,CacheNodeType,CacheClusterCreateTime,CacheClusterStatus,Monthly Cost,CPU 95th Percentile" >  elastic
}

awsinfo ()
{
echo "=== Starting awsinfo `date`"
aws ec2 describe-instances | jq -r  '.Reservations[].Instances[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.InstanceId),\(.InstanceType),\(.PrivateIpAddress),\(.PublicIpAddress),\(.PublicDnsName),\(.State.Name),\(.Platform),\(.LaunchTime),\(.VpcId),\(.SubnetId),\(.Placement.AvailabilityZone),\(.KeyName),\(.ImageId),\(.Monitoring.State),\(.BlockDeviceMappings[0].Ebs.VolumeId),\(.BlockDeviceMappings[1].Ebs.VolumeId),\(.BlockDeviceMappings[2].Ebs.VolumeId),\(.BlockDeviceMappings[3].Ebs.VolumeId),\(.BlockDeviceMappings[4].Ebs.VolumeId),\(.BlockDeviceMappings[5].Ebs.VolumeId),\(.BlockDeviceMappings[6].Ebs.VolumeId),\(.BlockDeviceMappings[7].Ebs.VolumeId),\(.BlockDeviceMappings[8].Ebs.VolumeId),\(.BlockDeviceMappings[9].Ebs.VolumeId),\(.SecurityGroups[0].GroupId),\(.SecurityGroups[1].GroupId),\(.SecurityGroups[2].GroupId),\(.SecurityGroups[3].GroupId),\(.SecurityGroups[4].GroupId),\($tags.Name),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc)"'  2>/dev/null | sed "1,\$s/^/$i,/" > temp.instances

aws ec2 describe-volumes | jq -r  '.Volumes[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.VolumeId),\(.VolumeType),\(.Encrypted),\(.State),\(.Size),\(.Attachments[0].InstanceId),\(.Attachments[0].State),\(.Attachments[0].DeleteOnTermination),\(.Attachments[0].Device),\($tags.Name),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc)"' 2>/dev/null  | sed "1,\$s/^/$i,/"  > temp.volumes

aws ec2 describe-snapshots | jq -r  '.Snapshots[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.SnapshotId),\(.StartTime),\(.VolumeSize),\(.Description),\(.VolumeId),\(.State),\(.Progress),\(.Encrypted),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc),\($tags.Name)"' 2>/dev/null | sed "1,\$s/^/$i,/" > temp.snapshots

aws ec2 describe-images  | jq -r  '.Images[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.ImageId),\(.CreationDate),\(.VirtualizationType),\(.Name),\(.BlockDeviceMappings[0].Ebs.VolumeSize),\(.Architecture),\(.Public),\($tags.Name),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc)"'  2>/dev/null | grep false | sed "1,\$s/^/$i,/" > temp.images

aws ec2 describe-vpcs | jq -r  '.Vpcs[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.VpcId),\(.CidrBlock),\(.DhcpOptionsId),\(.DhcpOptionsId),\(.IsDefault),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc)"' 2>/dev/null | sed "1,\$s/^/$i,/" >> VPCs
aws ec2 describe-subnets  | jq -r  '.Subnets[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.VpcId),\(.SubnetId),\(.AvailabilityZone),\(.CidrBlock),\(.AvailableIpAddressCount),\($tags.Product),\($tags.BusinessUnit),\($tags.Environment),\($tags.Owner),\($tags.CostCenter)"' 2>/dev/null | sed "1,\$s/^/$i,/" >> subnets
aws ec2 describe-route-tables | jq -r  '.RouteTables[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.RouteTableId),\(.VpcId),\(.Associations[0].Main),\(.Associations[0].SubnetId),\(.Associations[1].SubnetId),\(.Associations[2].SubnetId),\(.Associations[3].SubnetId),\(.Associations[4].SubnetId),\(.Associations[5].SubnetId),\(.Associations[6].SubnetId),\(.Associations[7].SubnetId),\(.Associations[8].SubnetId),\(.Associations[9].SubnetId),\(.Routes[0].DestinationCidrBlock),\(.Routes[1].DestinationCidrBlock),\(.Routes[2].DestinationCidrBlock),\(.Routes[3].DestinationCidrBlock),\(.Routes[4].DestinationCidrBlock),\(.Routes[5].DestinationCidrBlock),\(.Routes[6].DestinationCidrBlock),\(.Routes[7].DestinationCidrBlock),\(.Routes[8].DestinationCidrBlock),\(.Routes[9].DestinationCidrBlock),\($tags.Product),\($tags.BusinessUnit),\($tags.Environment),\($tags.Owner),\($tags.CostCenter),\($tags.Name)"' 2>/dev/null  | sed "1,\$s/^/$i,/" >> routetables

#    aws ec2 describe-security-groups | jq -r  '.SecurityGroups[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.GroupId),\(.GroupName),\(.IpPermissions[0].ToPort),\(.IpPermissions[0].IpProtocol),\(.IpPermissions[0].IpRanges),\($tags.Product),\($tags.BusinessUnit),\($tags.Environment),\($tags.Owner),\($tags.CostCenter),\($tags.Name)"' 2>/dev/null

aws elb describe-load-balancers | jq -r  '.LoadBalancerDescriptions[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.LoadBalancerName),\(.DNSName),\(.CreatedTime),\(.VPCId),\(.Subnets[0]),\(.Subnets[1]),\(.ListenerDescriptions[0].Listener.InstancePort),\(.ListenerDescriptions[0].Listener.LoadBalancerPort),\(.ListenerDescriptions[0].Listener.Protocol),\(.ListenerDescriptions[0].Listener.InstanceProtocol),\(.Instances[0].InstanceId),\(.Instances[1].InstanceId),\(.Instances[2].InstanceId),\(.Instances[3].InstanceId),\(.HealthCheck.HealthyThreshold),\(.HealthCheck.Interval),\(.HealthCheck.Target),\(.HealthCheck.Timeout),\(.HealthCheck.UnhealthyThreshold),\($tags.Product),\($tags.Bu),\($tags.Environment),\($tags.Owner),\($tags.Cc),\($tags.Name)"' 2>/dev/null | sed "1,\$s/^/$i,/" >> ELBs

aws rds describe-db-instances  | jq -r  '.DBInstances[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.DBInstanceIdentifier),\(.Engine),\(.DBSubnetGroup.VpcId),\(.AvailabilityZone),\(.MultiAZ),\(.DBInstanceClass),\(.StorageType),\(.AllocatedStorage),\(.InstanceCreateTime),\($tags.Product),\($tags.BusinessUnit),\($tags.Environment),\($tags.Owner),\($tags.CostCenter)"' 2>/dev/null | sed "1,\$s/^/$i,/"  > temp.rds

aws elasticache describe-cache-clusters |  jq -r  '.CacheClusters[] | (.Tags | map(.value=.Value | .key=.Key) | from_entries) as $tags | "\(.CacheClusterId),\(.Engine),\(.NumCacheNodes),\(.CacheNodeType),\(.CacheClusterCreateTime),\(.CacheClusterStatus)"' 2>/dev/null | sed "1,\$s/^/$i,/"  > temp.elastic

aws iam generate-credential-report >/dev/null; sleep 60
aws iam get-credential-report --output text --query Content  | base64 -d | sed "1,\$s/^/$i,/" >> IAM
}

calc95th ()
{
  l=`wc -l temp.95 | cut -d' ' -f1`
  l95=`echo "scale=0;$l*0.95"  | bc | cut -d'.' -f1`
  l95=`echo ${l95%.*}`
  c95=`grep "^$l95 " temp.95 | cut -d' ' -f2 `
}


s3bucketsizes ()
{
   for s in `aws s3 ls | awk ' { print $3 } '`
   do
        size=$(aws s3 ls s3://$s --recursive  | grep -v -E "(Bucket: |Prefix: |LastWriteTime|^$|--)" | awk 'BEGIN {total=0}{total+=$3}END{print total/1024/1024/1024" GB"}')
        echo "$i,$s,$size" >> S3
   done
}

summary ()
{
suminstances=$(expr `cat instances | wc -l` - 1)
suminstancescost=$(cat  instances | cut -d',' -f40 | awk ' { x+=$1; print x } ' | tail -1)

sumvolumes=$(expr `cat volumes | wc -l` - 1)
sumvolumescost=$(cat volumes  | cut -d',' -f17 |  awk ' { x+=$1; print x } ' | tail -1)

sumsnap=$(expr `cat snapshots | wc -l` - 1)
sumsnapcost=$(cat snapshots | cut -d',' -f16 |  awk ' { x+=$1; print x } ' | tail -1)

sumimages=$(expr `cat images | wc -l` - 1)
sumimagescost=$(cat images |  cut -d',' -f15 | awk ' { x+=$1; print x } ' | tail -1)

sumrds=$(expr `cat RDS | wc -l` - 1)
sumrdscost=$(cat RDS | cut -d',' -f18 | awk ' { x+=$1; print x } ' | tail -1)

sumelasti=$(expr `cat elastic | wc -l` - 1)
sumelasticcost=$(cat elastic | cut -d',' -f8 | awk ' { x+=$1; print x } ' | tail -1)

sumelb=$(expr `cat ELBs | wc -l` - 1)

sums3=$(expr `cat S3 | wc -l` - 1)
sums3cost=$(cat S3 | cut -d',' -f4 | awk ' { x+=$1; print x } ' | tail -1)

sumiamusers=$(expr `cat IAM | wc -l` - 1)
k1=`cat IAM | cut -d',' -f10  | grep true | wc -l`
k2=`cat IAM |  cut -d',' -f15  | grep true | wc -l`
sumiamkeys=`expr $k1 + $k2`

sumvpc=$(expr `cat VPCs | wc -l` - 1)
sumsubnets=$(expr `cat subnets | wc -l` - 1)
sumroute=$(expr `cat routetables | wc -l` - 1)

(
echo "Resource,Count,Monthly Cost Estimate (US$)"
echo "Instances,$suminstances,$suminstances"
echo "Volumes,$sumvolumes,$sumvolumescost"
echo "Snapshots,$sumsnap,$sumsnapcost"
echo "AMI images,$sumimages,$sumimagescost"
echo "RDS instances,$sumrds,$sumrdscost"
echo "ElastiCache instances,$sumelasti,$sumelasticcost"
echo "S3,$sums3,$sums3cost"
echo 
echo "ELBs,$sumelb"
echo "IAM users,$sumiamusers"
echo "IAM access keys,$sumiamkeys"
echo "VPCs,$sumvpc"
echo "Subnets,$sumsubnets"
echo "Route Tables,$sumroute"
) > Summary
}

makeexcel ()
{
python ./makeexcel.py
d=`date +%d`
m=`date +%m`
y=`date +%Y`
cp awsinfo.xls awsinfo-$d$m$y.xls
}

uploadS3 ()
{
export AWS_DEFAULT_PROFILE=actt1
aws s3 cp awsinfo-$d$m$y.xls s3://$s3bucket/awscmdb/awsinfo-$d$m$y.xls
}

cleanup ()
{
rm -rf temp.*
}

# Main
cd $basedir
headers

# For each AWS account gather AWS information
for i in $accounts
do
  echo -e "\n\n=== Starting Account=$i `date`\n\n"
  export AWS_DEFAULT_PROFILE=$i
  s=`date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'`

  awsinfo

echo "=== Starting volumes `date`"
# EBS volumes
  while read line; do
        v=`echo $line |  cut -d',' -f2`
        t=`echo $line |  cut -d',' -f3`
        sz=`echo $line |  cut -d',' -f6`
        c=`grep $t aws.costs | grep ebs | cut -d',' -f3`
        cost=`echo "scale=2;$sz*$c" | bc`

        for metric in VolumeIdleTime VolumeQueueLength VolumeReadOps VolumeWriteOps
        do
             aws cloudwatch get-metric-statistics --metric-name $metric --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --namespace AWS/EBS \
                  --statistics Maximum --dimensions Name=VolumeId,Value=$v | grep -i Maximum | cut -d':' -f2  | cut -d',' -f1 | sort -n | cat -n  | awk ' { print $1 " " $2 } ' > temp.95
             calc95th
             export ${metric}95=$c95
        done
        for metric in VolumeReadBytes VolumeWriteBytes 
        do
             aws cloudwatch get-metric-statistics --metric-name $metric --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --namespace AWS/EBS \
                  --statistics Average --dimensions Name=VolumeId,Value=$v | grep -i Average | cut -d':' -f2  | cut -d',' -f1 | sort -n | cat -n  | awk ' { print $1 " " $2 } ' > temp.95
             calc95th
             export ${metric}95=$c95
        done

        VolumeReadOps95=`echo "scale=2;$VolumeReadOps95/900" | bc`
        VolumeWriteOps95=`echo "scale=2;$VolumeWriteOps95/900" | bc`
        echo "$line,$cost,$VolumeIdleTime95,$VolumeQueueLength95,$VolumeReadBytes95,$VolumeWriteBytes95,$VolumeReadOps95,$VolumeWriteOps95" >> volumes
  done < temp.volumes

echo "=== Starting snapshots `date`"
# Snapshots
  c=`grep ebssnapshot aws.costs | cut -d',' -f2`
  while read line; do
        sz=`echo $line |  cut -d',' -f4`
        cost=`echo "scale=2;$sz*$c" | bc`
        desc=`echo $line |  cut -d',' -f6`
        echo "$line,$cost" >> snapshots
  done < temp.snapshots



echo "=== Starting instances `date`"
# EC2 instances
  while read line; do
        c=`echo $line |  cut -d',' -f2`
        si=`echo $line |  cut -d',' -f9`
        platform=`echo $line |  cut -d',' -f8`
        [ "$platform" == "null" ] && platform="linux" || platform=$platform
        t=`echo $line |  cut -d',' -f3`
        cpu=`grep $t aws.costs | grep ec2 | cut -d',' -f7`
        ip=`echo $line |  cut -d',' -f4`
        (( "$platform" == "windows" )) && cost=`grep $t aws.costs | grep ec2 | cut -d',' -f6` || cost=`grep $t aws.costs | grep ec2 | cut -d',' -f6`
        (( $(date -d "$si" +%s) < $(date -d "$s" +%s) )) && start=$s || start=$si
        days=$(echo "scale=2;(`date +%s`-`date -d "$si" +%s`)/86400" | bc)
        D=`echo ${days%.*}`
        [ "$D" == "" ] && D=0 || D=$D
        vols=`echo $line | awk -F',' ' { print $16 " " $17 " " $18 " " $19 " " $20 " " $21 " " $22 " " $23 " " $24 " " $25 } '`
#       cat temp.cw | jq -r  '.Datapoints[] | "\(.Timestamp),\(.Maximum)"' 2>/dev/null | sort

        aws cloudwatch get-metric-statistics --metric-name CPUUtilization --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --namespace AWS/EC2 \
                  --statistics Maximum --dimensions Name=InstanceId,Value=$c > temp.cw
        cat temp.cw | grep -i Maximum | cut -d':' -f2  | cut -d',' -f1 | sort -n | cat -n  | awk ' { print $1 " " $2 } ' > temp.95
        calc95th
        cpu95=$c95

        cat temp.cw | jq -r  '.Datapoints[] | "\(.Timestamp),\(.Maximum)"' 2>/dev/null | sort | grep 'T16:' > /dev/null 2>&1
        x=$?
        [ $x -eq 0 ] && runnight="true" || runnight="false"

        for metric in DiskReadBytes DiskReadOps DiskWriteBytes DiskWriteOps NetworkIn NetworkOut
        do
             aws cloudwatch get-metric-statistics --metric-name $metric --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --namespace AWS/EC2 \
                  --statistics Maximum --dimensions Name=InstanceId,Value=$c | grep -i Maximum | cut -d':' -f2  | cut -d',' -f1 | sort -n | cat -n  | awk ' { print $1 " " $2 } ' > temp.95
             calc95th
             export ${metric}95=$c95
        done
        DsikReadOps95=`echo "scale=2;$DiskReadOps95/900" | bc`
        DiskWriteOps95=`echo "scale=2;$DiskWriteOps95/900" | bc`
        NetworkIn95=`echo "scale=2;$NetworkIn95/900" | bc`
        NetworkOut95=`echo "scale=2;$NetworkOut95/900" | bc`

        if [ $(date -d "$si" +%s) -le $(date -d "$s" +%s) ]
        then
           prunning=`echo "scale=1;100*$l/1440" | bc`
        else
           daysrunning=$(echo "scale=2;$l*15/1440" | bc)
           prunning=$(echo "scale=1;$daysrunning/$days" | bc)
        fi

        if [ $D -le 15 ]
        then
             length=under-15days
        else
             length=over-15days
        fi

        vt=0;vszt=0
        st=0
        for v in `echo $vols`
        do
           [ "$v" == "null" ] && vc=0 || vc=`grep $v volumes |  cut -d',' -f17`
           [ "$v" == "null" ] && vsz=0 || vsz=`grep $v volumes |  cut -d',' -f6`
           [ "$v" == "null" ] && sc=0 || sc=`grep $v snapshots |  cut -d',' -f16 | awk ' { x+=$1; print x } ' | tail -1`
           [ "$sc" == "" ] && sc=0 || sc=$sc
           vszt=`echo "scale=0;$vszt+$vsz" | bc`
           vt=`echo "scale=2;$vt+$vc" | bc`
           st=`echo "scale=2;$st+$sc" | bc`
        done

        echo "$line,$vszt,$cpu95,$cpu,$prunning,$cost,$vt,$st,$days,$length,$runnight,$DiskReadBytes95,$DiskWriteOps95,$DiskReadOps95,$DiskWriteOps95,$NetworkIn95,$NetworkOut95" >> instances
  done < temp.instances


echo "=== Starting images `date`"
# AMI images
  c=`grep ebssnapshot aws.costs | cut -d',' -f2`
  while read line; do
        a=`echo $line |  cut -d',' -f2`
        sz=`echo $line |  cut -d',' -f6`
        cost=`echo "scale=2;$sz*$c" | bc`
        echo "$line,$cost" >> images
  done < temp.images


echo "=== Starting RDS `date`"
# RDS
  while read line; do
        c=`echo $line |  cut -d',' -f2`
        si=`echo $line |  cut -d',' -f9`
        t=`echo $line |  cut -d',' -f7`
        db=`echo $line |  cut -d',' -f3`
        maz=`echo $line |  cut -d',' -f6`
        [ "$maz" == "true" ] && cost=`grep $t aws.costs | grep -i $db | cut -d',' -f4` || cost=`grep $t aws.costs | grep -i $db | cut -d',' -f5`
        (( $(date -d "$si" +%s) < $(date -d "$s" +%s) )) && start=$s || start=$si
        aws cloudwatch get-metric-statistics --metric-name CPUUtilization --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --namespace AWS/RDS \
                        --statistics Maximum --dimensions Name=DBInstanceIdentifier,Value=$c | grep -i Maximum  | cut -d':' -f2  | cut -d',' -f1 | sort -n | cat -n  | awk ' { print $1 " " $2 } ' > temp.95
        calc95th
        cpu95=$c95

        prunning=`echo "scale=1;100*$l/1440" | bc`
        echo "$line,$cpu95,$prunning,$cost" >> RDS
  done < temp.rds

echo "=== Starting Elasticache `date`"
# Elasticache
  while read line; do
        c=`echo $line |  cut -d',' -f2`
        t=`echo $line |  cut -d',' -f5`
        cost=`grep $t aws.costs | cut -d',' -f3`
        aws cloudwatch get-metric-statistics --metric-name CPUUtilization --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --namespace AWS/ElastiCache \
                        --statistics Maximum --dimensions Name=CacheClusterId,Value=$c | grep -i Maximum  | cut -d':' -f2  | cut -d',' -f1 | sort -n | cat -n  | awk ' { print $1 " " $2 } ' > temp.95
        calc95th
        cpu95=$c95
        echo "$line,$cost,$cpu95" >> elastic
  done < temp.elastic

echo "=== Starting S3 `date`"
# S3
   c=`grep "^S3" aws.costs |  cut -d',' -f2`
   for s in `aws s3 ls | awk ' { print $3 } '`
   do
         size=$(aws cloudwatch get-metric-statistics --namespace AWS/S3  --start-time `date --date="15 days ago" +'%Y-%m-%dT%H:%M:00'` --end-time `date  +'%Y-%m-%dT%H:%M:00'` --period 900 --statistics Average  \
            --region ap-southeast-2 --metric-name BucketSizeBytes --dimensions Name=BucketName,Value=$s Name=StorageType,Value=StandardStorage | grep -i Average | cut -d':' -f2  | cut -d',' -f1 | sort -n | tail -1)
         if [ -z "$size" ]
         then
             size=0
         fi
         sz=`echo "scale=5;$size/1024/1024/1024" | bc`
         cost=`echo "scale=2;$c*$sz" | bc`
         echo "$i,$s,$sz,$cost" >> S3
  done

done

summary

echo "=== Starting makeexcel `date`"
makeexcel
uploadS3
cleanup

echo -e "\n\n=== awsinfo completed `date`"

exit 0
