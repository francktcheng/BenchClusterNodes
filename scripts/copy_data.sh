#!/bin/bash

## first copy a data into head node local disk folder (e.g./scratch )
cur_dir=$(pwd) 
dst_dir=/scratch/lc37

cp -r ${cur_dir}/../NodeBenchData ${dst_dir}

## ssh copy from local disk to other nodes local disk
for host in `cat hosts.lst`;do
    scp -r ${dst_dir}/NodeBenchData lc37@${host}:${dst_dir}/
done
