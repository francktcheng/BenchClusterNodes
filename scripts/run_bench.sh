#!/bin/bash

## configurations by users

work_dir=$(pwd)

## optional recommend to load the BenchData dir to local disk of each node
## if the dataset is located on shared filesystem, the loading data process will
## slow down the whole filesystem and thus affect other users
data_dir=/scratch/lc37/NodeBenchData/fascia

## default log dir
log_dir=${work_dir}/../Bench-Test
mkdir -p ${log_dir}
rm -rf ${log_dir}/*

## ------ run fascia-bench ----------------
## name of benchmark program

executor=fascia

## paras of benchmark program
# graph_file=gnp.1.20.graph
graph_file=miami.graph
template_file=u12-2.fascia
# template_file=u5-1.fascia
## omp thread affinity
affinity_typ=scatter
## num of omp threads
thd=24
## num of iterations 
itr=1

## ------------ check the multi-node hosts file and run scripts ------------

if [ -f "hosts.lst" ];then

    if [ -f "run_${executor}.sh" ];then
        ## run bench
        for line in `cat hosts.lst`;do
        	ssh $line ${work_dir}/run_${executor}.sh ${work_dir} ${data_dir} ${log_dir} ${graph_file} ${template_file} ${affinity_typ} ${thd} ${itr} &
        done
    else
        echo "script of ${executor} not found"
        exit
    fi

else
    echo "host file not found"
    exit
fi

## ------------ waiting for jobs on each host node ------------

while true; do

    flag=0
    for line in `cat hosts.lst`; do
        count=$( ssh $line pgrep ${executor} | wc -l )
        if [ $count -ne 0 ];then
            flag=1
            break
        fi
    done

    ## if flag remains 0 all the executor terminated
	if [ $flag -ne 0 ];then
        ## still have running executors
        echo "Benchmark Program still running"
        sleep 5
    else
        ## exit the while loop
        break
    fi

done

## all the bench executor finished on host nodes list
echo "Bench Test Finished"


# --------------------- analyze the results ---------------------
echo "Start Analyzing Results"
cd ${log_dir} 
extension=round3
exp_id=${executor}-${extension}
bench_res=bench-res-${exp_id}.txt
# rm -rf ${bench_res}

echo "Results from hosts" > ${bench_res} 

shopt -s globstar
for res in **/*.log; 
do # Whitespace-safe and recursive

    ## retrieve the hostname of each node
    if [[ $res =~ host-(.+).log  ]]; then
        hostname=${BASH_REMATCH[1]}
        echo "Host: ${hostname}" >> ${bench_res}
        ## search for time string 
        exetime=$( cat ${res} | grep "Time for count:" | awk '{print $4}')
        echo "Running Time: ${exetime}" >> ${bench_res}
    else
        echo "unable to find node for $res"
    fi

done

## archive the results file
if [ -d ${exp_id} ];then
	rm -rf ${exp_id}
fi
mkdir -p ${exp_id} 
mv *.log ${exp_id}
mv ${bench_res} ${exp_id}

echo "Analyzing finished"
