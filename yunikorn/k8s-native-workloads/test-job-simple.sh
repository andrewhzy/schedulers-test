export QUEUE=root.ns-a.tenant-low-priority
export TIMESTAMP=$(date +%s)
export COMPLETIONS=1000
export PARALLELISM=12
export SLEEP_DURATION=600
export MIN_MEMORY="1024Mi"
export MIN_CPU="200m"
export MAX_MEMORY="1024Mi"
export MAX_CPU="200m"
envsubst < test-job-simple.yaml | kubectl apply -f -;
sleep 2;
export QUEUE=root.ns-a.tenant-normal-priority
export TIMESTAMP=$(date +%s)
export COMPLETIONS=1000
export PARALLELISM=1
export SLEEP_DURATION=600
export MIN_MEMORY="1024Mi"
export MIN_CPU="200m"
export MAX_MEMORY="1024Mi"
export MAX_CPU="200m"
envsubst < test-job-simple.yaml | kubectl apply -f -;
