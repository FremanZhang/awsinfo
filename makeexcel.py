#!/usr/bin/python
import os
import glob
import csv
import xlwt


s = [ "instances", "volumes", "images" , "snapshots" , "VPCs" , "subnets" , "routetables" , "SGs" , "ELBs" , "RDS" , "IAM" , "S3" , "elastic" , "launchconfig" , "autoscale" , "aws.costs" , "heatmap" , "heatmap.cost" , "heatmap.perf" , "Summary" ]
#floatstarts = [ 39, 17, 15, 16, 100, 100, 100, 100, 100, 18, 100, 2, 15, 100, 100, 100, 1, 1, 1  1 ]
floatstarts = [ 39, 17, 100, 100, 100, 100, 100, 100, 100, 18, 100, 2, 15, 100, 100, 100, 1, 1, 1, 1 ]
Matrix = [[0 for x in range(80)] for x in range(80)] 
Matrix[0][47] = 1
Matrix[0][48] = 1
Matrix[0][62] = 1
Matrix[8][37] = 1
Matrix[9][37] = 1
Matrix[12][28] = 1

workbook = xlwt.Workbook(encoding='utf-8')
x=0
for csvfile in s:
     print csvfile
     worksheet = workbook.add_sheet(csvfile)
     style = xlwt.easyxf('alignment: horiz centre')
     with open(csvfile, 'rb') as f:
        reader = csv.reader(f)
        for r, row in enumerate(reader):
            for c, value in enumerate(row):
                #print "r is {0} and c is {1}, value is {2}".format(r, c, value)
                if ( (c >= floatstarts[x]) and (r != 0)):
                    if ( Matrix[x][c] == 1):
                        worksheet.write(r, c, str(value), style)
                    else:
                        value = value or "0"
                        style.num_format_str = '0.00'
                        worksheet.write(r, c, float(value), style)
                else:
                    worksheet.write(r, c, value, style)
     x += 1
     for i in range(0,80):
          worksheet.col(i).width = 30 * 256
workbook.save("awsinfo.xls")
