# awsinfo

1. Daily Inventory of all AWS resources:
    - EC2 instance
    - EBS volumes
    - EBS snapshots
    - RDS instances
    - Elasticache
    - Elastic Load Balancers
    - S3
    - VPCs
    - Subnet
    - Routing Tables
    - IAM
2. Performance utilisation of above resources based on 95th percentile
3. Cost for each resource and total cost for each AWS service
4. When instances running (day/night), percentage


Why?
- CMDB of AWS resources
- Right size resources based on historical performance data 
- Use Reserved Instances
- Stop instances at night/weekends 
- Terminate/stop unused instance/volumes/snapshots

How to get it running:
- Install AWS CLI
- create AWS CLI profiles for all required accounts
- It uses python library xlwt to create Excel spreadsheet. To install: pip install xlwt
- Customise three environment variables in awsinfo.sh:
       - basedir: where awsinfor will reside
       - accounts: list of AWS accounts (or AWS CLI profiles)
       - s3bucket: name of s3bucket where to upload Excel spreadsheet
- Add awsinfo to daily cron job such as: 0 11 * * * /usr/local/awsinfo/awsinfo.sh > /usr/local/awsinfo/awsinfo.out 2>&1


