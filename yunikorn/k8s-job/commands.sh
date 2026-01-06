
export QUEUE=root.ns-a.tenant-a
export TIMESTAMP=$(date +%s)
export COMPLETIONS=1000
export PARALLELISM=20
export SLEEP_DURATION=600
export MIN_MEMORY="500Mi"
export MIN_CPU="100m"
export MAX_MEMORY="500Mi"
export MAX_CPU="100m"
envsubst < test-job-simple.yaml | kubectl apply -f -;
sleep 5;
export QUEUE=root.ns-a.tenant-b
export TIMESTAMP=$(date +%s)
export COMPLETIONS=100
export PARALLELISM=5
export SLEEP_DURATION=600
export MIN_MEMORY="500Mi"
export MIN_CPU="100m"
export MAX_MEMORY="500Mi"
export MAX_CPU="100m"
envsubst < test-job-simple.yaml | kubectl apply -f -;