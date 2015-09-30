#!/bin/bash
aws ec2 stop-instances --instance-ids $1
sleep 120
echo aws ec2 modify-instance-attribute --instance-id $1 --instance-type "{\"Value\":\"$2\"}"
sleep 10
echo aws ec2 start-instances --instance-ids $1
