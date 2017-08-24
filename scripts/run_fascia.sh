#!/bin/bash

## benchmark scripts on each node
work_dir=$1
data_dir=$2
log_dir=$3
graph_file=$4
template_file=$5
affinity_typ=$6
thd=$7
itr=$8

## by default path
executor_dir=${work_dir}/../src/fascia

graph_name=$(echo "$graph_file" | cut -d'.' -f1 )
template_name=$(echo "$template_file" | cut -d'.' -f1 )

## get core num per socket
cps=$(lscpu | grep "Core(s) per socket" | awk '{ print $4  }')
## get num of sockets
spn=$(lscpu | grep "Socket(s)" | awk '{ print $2  }')
## calculate total core num
core_num=$((${spn}*${cps})) 

host_id=$(hostname)
logName=FasciaTest-$graph_name-$template_name-Thd-$thd-Core-$core_num-Itr-$itr-$affinity_typ-host-${host_id}.log

export OMP_NUM_THREADS=$thd
export OMP_PLACES=cores 

if [ "$affinity_typ" == "compact" ];then
    export OMP_PROC_BIND=close
else
    export OMP_PROC_BIND=spread
fi

${executor_dir}/fascia -g ${data_dir}/graph/${graph_file} -t ${data_dir}/template/${template_file} -i $itr -r -v &> ${log_dir}/${logName} 
echo "Benchmark fascia finished on host ${host_id}"
