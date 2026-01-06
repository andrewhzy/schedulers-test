
# Reproduce HOL(Head Of Line) blocking with default scheduler
argowf yaml: @spark-pi-workflow.yaml
### 1. simulate a large long-running spark job which consumes all(almost) resources:
```
argo submit spark-pi-workflow.yaml \
    -p image=apache/spark:3.5.7 \
    -p partitions=1000000 \
    -p namespace=yunikorn-spark-submit \
    -p executors=16
```
screenshot:
![alt text](image-1.png)

### 2. simulate a small short spark job, which we expect low latency:
```
argo submit spark-pi-workflow.yaml \
    -p image=apache/spark:3.5.7 \
    -p partitions=10000 \
    -p namespace=yunikorn-spark-submit \
    -p executors=1
```
screenshot:
![alt text](image-2.png)

## conclusion: 
with default scheduler and limited resources, there will be HOL blocking, large long-running spark jobs consume all resources will block future jobs in the same ns.

---

# Resolve HOL blocking with yunikorn

### 1. clear all workloads:
![alt text](image-3.png)

### 2. install yunikorn and config queues
parent queue:
![alt text](image-5.png)
child: root.ns-a.tenant-a
![alt text](image-7.png)
child: root.ns-a.tenant-b
![alt text](image-10.png)

### 3. simulate a large long-running spark job which consume all(almost) allocated resources:
specify yunikorn as the scheduler and a child queue for scheduling
```
argo submit spark-pi-workflow.yaml \
    -p image=apache/spark:3.5.7 \
    -p partitions=20000 \
    -p namespace=yunikorn-spark-submit \
    -p executors=6 \
    -p queue=root.ns-a.tenant-a \
    -p scheduler=yunikorn
```
wait for some momemt will see:
![alt text](image-11.png)

### 4. simulate a small short spark job, which we expect low latency:
specify yunikorn as the scheduler and another child queue for scheduling
```
argo submit spark-pi-workflow.yaml \
    -p image=apache/spark:3.5.7 \
    -p partitions=10000 \
    -p namespace=yunikorn-spark-submit \
    -p executors=2 \
    -p queue=root.ns-a.tenant-b \
    -p scheduler=yunikorn
```
wait for some momemt will see:
![alt text](image-12.png)
1. sompe of the exec pods of the first job was preempted, and new ones created but in pending state.
2. the 2nd spark job was able to run, because it runs on a different queue with guaranteed resource quota. and can preempt pods on a queue which consumes more the guaranteed

## conclusion: 
with yunikorn scheduler and child queues with guaranteed resource quota, and preemption enabled, HOL blocking can be resolved, large long-running spark jobs running on queues consuming more than guaranteed can be preempted by jobs running on another queue that does not fulfill its guaranteed resource quota.


