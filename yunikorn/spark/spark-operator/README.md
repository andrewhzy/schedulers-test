# Custom Spark Application on Kubernetes

A complete example showing how to build and deploy a custom PySpark application on Kubernetes using the Spark Operator.

## Overview

This example demonstrates:
- Creating a custom PySpark application (word count)
- Packaging the application in a Docker image
- Deploying to Kubernetes using the Spark Operator
- Monitoring and viewing results

## Prerequisites

Before you begin, ensure you have:

1. **Docker** installed and running
2. **kubectl** configured to access your Kubernetes cluster
3. **Spark Operator** installed in your cluster
   - Installation guide: https://github.com/kubeflow/spark-operator
4. **Service Account** `spark-operator-spark` with proper RBAC permissions
5. (Optional) Access to a container registry for storing images

## Quick Start

Get up and running in 3 steps:

```bash
# 1. Build the Docker image
./build.sh

# 2. Deploy to Kubernetes
./deploy.sh

# 3. View the results
kubectl logs -f spark-wordcount-driver
```

## Project Structure

```
.
├── app/
│   └── wordcount.py           # PySpark word count application
├── data/
│   └── sample-text.txt        # Sample input data (Shakespeare excerpts)
├── Dockerfile                 # Custom Spark image definition
├── spark-pi.yaml             # Reference example (Scala)
├── spark-wordcount.yaml      # Python word count deployment config
├── build.sh                  # Build automation script
├── deploy.sh                 # Deployment automation script
└── README.md                 # This file
```

## Building the Docker Image

### Local Testing (No Registry Required)

For local testing, build the image directly on your Kubernetes nodes:

```bash
# Build the image
./build.sh

# Or manually:
docker build -t spark-wordcount:latest .
```

**Important**: When using local images, ensure `spark-wordcount.yaml` has:
```yaml
image: spark-wordcount:latest
imagePullPolicy: Never  # or IfNotPresent
```

### Using a Container Registry

To use a remote registry (Docker Hub, GCR, ECR, etc.):

1. **Edit `build.sh`** and set the `REGISTRY` variable:
   ```bash
   REGISTRY="docker.io/yourusername"  # For Docker Hub
   # REGISTRY="gcr.io/your-project"   # For Google Container Registry
   # REGISTRY="your-ecr-url"          # For AWS ECR
   ```

2. **Build and push**:
   ```bash
   ./build.sh
   docker push docker.io/yourusername/spark-wordcount:latest
   ```

3. **Update `spark-wordcount.yaml`**:
   ```yaml
   image: docker.io/yourusername/spark-wordcount:latest
   imagePullPolicy: IfNotPresent  # or Always
   ```

## Deploying to Kubernetes

### Deploy the Application

```bash
./deploy.sh
```

The script will:
- Check prerequisites (kubectl, Spark Operator, service account)
- Delete any existing application
- Apply the SparkApplication configuration
- Show status and monitoring commands

### Manual Deployment

If you prefer to deploy manually:

```bash
# Apply the configuration
kubectl apply -f spark-wordcount.yaml

# Check status
kubectl get sparkapplication spark-wordcount

# View driver logs
kubectl logs -f spark-wordcount-driver
```

## Monitoring and Viewing Results

### Check Application Status

```bash
# View SparkApplication status
kubectl get sparkapplication spark-wordcount

# Watch for status changes
kubectl get sparkapplication spark-wordcount -w
```

Expected status progression: `SUBMITTED` → `RUNNING` → `COMPLETED`

### View Driver Logs

The word count results are printed in the driver logs:

```bash
kubectl logs -f spark-wordcount-driver
```

You should see output like:

```
Top 20 most frequent words:
----------------------------------------
 1. the                      156
 2. and                       98
 3. to                        87
 4. of                        76
 5. is                        54
...
----------------------------------------
```

### View Executor Logs

```bash
# List all pods
kubectl get pods | grep spark-wordcount

# View specific executor logs
kubectl logs spark-wordcount-exec-1
kubectl logs spark-wordcount-exec-2
```

### Check Output Files

The results are written to `/tmp/wordcount-output` in CSV format:

```bash
# Access the driver pod
kubectl exec -it spark-wordcount-driver -- /bin/bash

# View output files
ls -la /tmp/wordcount-output/
cat /tmp/wordcount-output/*.csv
```

## Customization

### Using Your Own Data

#### Option 1: Modify the Docker Image

1. Replace `data/sample-text.txt` with your data
2. Rebuild the image: `./build.sh`
3. Redeploy: `./deploy.sh`

#### Option 2: Use External Storage

Modify `spark-wordcount.yaml` to use cloud storage:

```yaml
arguments:
  - "s3a://your-bucket/input/data.txt"      # AWS S3
  # - "gs://your-bucket/input/data.txt"     # Google Cloud Storage
  # - "wasbs://your-container/input/data"   # Azure Blob Storage
  - "s3a://your-bucket/output/"
```

**Note**: You'll need to configure credentials (see Cloud Storage Integration below)

#### Option 3: Use ConfigMap or PersistentVolume

```yaml
spec:
  driver:
    volumeMounts:
      - name: input-data
        mountPath: /mnt/data
  volumes:
    - name: input-data
      configMap:
        name: my-input-data
```

### Adjusting Resources

Edit `spark-wordcount.yaml` to modify CPU and memory:

```yaml
driver:
  coreRequest: "200m"   # Increase CPU request
  coreLimit: "1000m"    # Increase CPU limit
  memory: 1g            # Increase memory
  memoryOverhead: 200m

executor:
  instances: 4          # More executors for larger datasets
  coreRequest: "500m"
  coreLimit: "2000m"
  memory: 2g
  memoryOverhead: 400m
```

### Adding Python Dependencies

If your application needs additional packages:

1. **Update Dockerfile**:
   ```dockerfile
   FROM apache/spark:4.0.0

   # Install additional packages
   USER root
   RUN pip install --no-cache-dir pandas numpy scikit-learn

   # Copy application code
   WORKDIR /opt/spark/work-dir
   COPY app/wordcount.py /opt/spark/work-dir/
   COPY data/sample-text.txt /opt/spark/work-dir/data/

   RUN chown -R 185:185 /opt/spark/work-dir
   USER 185
   ```

2. **Rebuild**: `./build.sh`

### Cloud Storage Integration

#### AWS S3

1. **Add AWS credentials to `spark-wordcount.yaml`**:
   ```yaml
   spec:
     hadoopConf:
       "fs.s3a.access.key": "YOUR_ACCESS_KEY"
       "fs.s3a.secret.key": "YOUR_SECRET_KEY"
       # Or use IAM roles (recommended)
       "fs.s3a.aws.credentials.provider": "com.amazonaws.auth.InstanceProfileCredentialsProvider"
   ```

2. **Update arguments**:
   ```yaml
   arguments:
     - "s3a://your-bucket/input/data.txt"
     - "s3a://your-bucket/output/"
   ```

#### Google Cloud Storage

1. **Create service account key secret**:
   ```bash
   kubectl create secret generic gcs-key --from-file=key.json=your-service-account-key.json
   ```

2. **Update `spark-wordcount.yaml`**:
   ```yaml
   spec:
     hadoopConf:
       "google.cloud.auth.service.account.json.keyfile": "/mnt/secrets/key.json"
     driver:
       volumeMounts:
         - name: gcs-key
           mountPath: /mnt/secrets
     volumes:
       - name: gcs-key
         secret:
           secretName: gcs-key
   ```

## Troubleshooting

### Image Pull Errors

**Error**: `ErrImagePull` or `ImagePullBackOff`

**Solutions**:
- For local images, ensure `imagePullPolicy: Never` in YAML
- For registry images, verify the image exists: `docker pull your-image:tag`
- Check registry credentials if using private registry

### Permission Denied Errors

**Error**: Permission denied when writing output

**Solutions**:
- Use `/tmp` for output (world-writable)
- Or configure PersistentVolume with proper permissions
- Ensure security context allows user 185 to write

### Service Account Not Found

**Error**: Service account "spark-operator-spark" not found

**Solutions**:
```bash
# Create service account
kubectl create serviceaccount spark-operator-spark

# Create role binding (adjust as needed)
kubectl create clusterrolebinding spark-role \
  --clusterrole=edit \
  --serviceaccount=default:spark-operator-spark
```

### Spark Operator Not Installed

**Error**: SparkApplication CRD not found

**Solution**: Install the Spark Operator:
```bash
# Using Helm
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --create-namespace
```

### Application Stuck in SUBMITTED

**Possible causes**:
1. Insufficient cluster resources
2. Image pull issues
3. RBAC permission problems

**Debug**:
```bash
# Check application details
kubectl describe sparkapplication spark-wordcount

# Check driver pod
kubectl get pods | grep spark-wordcount
kubectl describe pod spark-wordcount-driver

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Out of Memory Errors

**Solutions**:
- Increase driver/executor memory in YAML
- Reduce executor instances or data size
- Add more memory overhead:
  ```yaml
  memoryOverhead: 512m  # Default is 100m
  ```

## Development Tips

### Local Testing (Without Kubernetes)

Test your PySpark code locally before deploying:

```bash
# Install PySpark locally
pip install pyspark==3.5.0

# Run locally
spark-submit app/wordcount.py data/sample-text.txt output/
```

### Iterative Development

For faster iterations during development:

1. Make code changes in `app/wordcount.py`
2. Rebuild: `./build.sh`
3. Redeploy: `./deploy.sh`
4. Check logs: `kubectl logs -f spark-wordcount-driver`

### Debugging in the Pod

Access the driver pod for debugging:

```bash
# Shell into driver pod
kubectl exec -it spark-wordcount-driver -- /bin/bash

# Check file system
ls -la /opt/spark/work-dir/
cat /opt/spark/work-dir/wordcount.py

# Check Python environment
python3 --version
pip list
```

## Next Steps

Now that you have a working custom Spark application, consider:

### 1. More Complex Applications
- Data transformations and aggregations
- Joining multiple datasets
- Machine learning with MLlib
- Streaming applications with Structured Streaming

### 2. Production Readiness
- Add comprehensive error handling
- Implement data validation
- Set up logging and monitoring (Prometheus, Grafana)
- Configure History Server for job history

### 3. CI/CD Integration
- Automate builds with GitHub Actions or GitLab CI
- Automated testing of Spark applications
- Continuous deployment to Kubernetes

### 4. Advanced Features
- Dynamic resource allocation
- Spot/preemptible instances for cost optimization
- Custom metrics and monitoring
- Integration with data catalogs (Hive, Glue)

### 5. Scale Up
- Process larger datasets
- Optimize Spark configurations
- Tune resource allocation
- Implement data partitioning strategies

## Additional Resources

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Spark Operator Documentation](https://github.com/kubeflow/spark-operator)
- [PySpark API Reference](https://spark.apache.org/docs/latest/api/python/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

This example is based on the Apache Spark examples and follows the Apache License 2.0.
