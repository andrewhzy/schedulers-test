
export QUEUE=root.ns-a.tenant-a
export TIMESTAMP=$(date +%s)
export COMPLETIONS=1000
export PARALLELISM=20
export SLEEP_DURATION=600
export MIN_MEMORY="600Mi"
export MIN_CPU="190m"
export MAX_MEMORY="600Mi"
export MAX_CPU="190m"
envsubst < test-job-simple.yaml | kubectl apply -f -;
sleep 5;
export QUEUE=root.ns-a.tenant-b
export TIMESTAMP=$(date +%s)
export COMPLETIONS=100
export PARALLELISM=5
export SLEEP_DURATION=600
export MIN_MEMORY="600Mi"
export MIN_CPU="190m"
export MAX_MEMORY="600Mi"
export MAX_CPU="190m"
envsubst < test-job-simple.yaml | kubectl apply -f -;