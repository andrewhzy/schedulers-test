# Implementation Plan: Build Custom PySpark Application on Kubernetes

## Overview
Create a complete example showing how to build and deploy a custom PySpark application on Kubernetes using the Spark Operator. The example will be a word count application packaged in a custom Docker image.

## User Requirements
- **Language**: Python/PySpark
- **Packaging**: Custom Docker image based on `apache/spark:4.0.0`
- **Starting Point**: Simple example (word count)
- **Reference**: Existing `spark-pi.yaml` for security and resource settings

## Project Structure
```
/Users/hzy/projects/k8s/spark/spark-operator/my-example/
├── spark-pi.yaml                    # Existing reference (keep as-is)
├── app/
│   └── wordcount.py                 # PySpark application
├── data/
│   └── sample-text.txt              # Sample input data
├── Dockerfile                       # Custom image definition
├── spark-wordcount.yaml             # SparkApplication deployment config
├── build.sh                         # Build automation script
├── deploy.sh                        # Deployment script
└── README.md                        # Complete documentation
```

## Implementation Steps

### Step 1: Create PySpark Application
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/app/wordcount.py`

**Requirements**:
- Accept input/output paths as command-line arguments
- Read text file and perform word count
- Sort results by frequency (descending)
- Write output to specified location
- Print top 20 words to logs for verification
- Include proper error handling

**Key Implementation Details**:
- Use PySpark DataFrame API (modern approach)
- Handle command-line arguments: `sys.argv[1]` for input, `sys.argv[2]` for output
- Create SparkSession with descriptive app name
- Use transformations: `flatMap()`, `map()`, `reduceByKey()`, `sortBy()`
- Write output as text/parquet
- Log results for easy debugging

### Step 2: Create Sample Data
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/data/sample-text.txt`

**Requirements**:
- Include meaningful text (10-50KB)
- Diverse vocabulary for interesting results
- Suggestion: Use public domain text (Shakespeare excerpt or similar)

### Step 3: Create Dockerfile
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/Dockerfile`

**Base Image**: `apache/spark:4.0.0` (matches spark-pi.yaml)

**Instructions**:
1. Copy `app/wordcount.py` to `/opt/spark/work-dir/`
2. Copy `data/sample-text.txt` to `/opt/spark/work-dir/data/`
3. Set working directory to `/opt/spark/work-dir`
4. Maintain user 185 (non-root, matches security context)

**Security Considerations**:
- Run as user 185 (same as spark-pi.yaml)
- No additional capabilities needed
- Minimal layers for smaller image size

### Step 4: Create SparkApplication YAML
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/spark-wordcount.yaml`

**Approach**: Clone `spark-pi.yaml` and modify for Python

**Changes Required**:
- `metadata.name`: `spark-wordcount`
- `spec.type`: `Python` (was Scala)
- Add `spec.pythonVersion`: `"3"`
- `spec.image`: `<user-registry>/spark-wordcount:latest` (or local for testing)
- `spec.mainApplicationFile`: `local:///opt/spark/work-dir/wordcount.py`
- `spec.arguments`:
  - `"local:///opt/spark/work-dir/data/sample-text.txt"` (input)
  - `"local:///tmp/wordcount-output"` (output)

**Settings to PRESERVE from spark-pi.yaml**:
- All security context settings (driver and executor)
- Resource limits (coreRequest: 100m, coreLimit: 500m, memory: 480m)
- Service account: `spark-operator-spark`
- Image pull policy: `IfNotPresent`
- Executor instances: 2
- Spark version: 4.0.0

### Step 5: Create Build Script
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/build.sh`

**Features**:
- Build Docker image with tag `spark-wordcount:latest`
- Support optional registry tagging
- Display build status and image info
- Make executable with proper error handling

**Key Commands**:
```bash
docker build -t spark-wordcount:latest .
docker images | grep spark-wordcount
```

### Step 6: Create Deployment Script
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/deploy.sh`

**Features**:
- Apply SparkApplication YAML
- Show deployment status
- Provide log viewing commands

**Key Commands**:
```bash
kubectl apply -f spark-wordcount.yaml
kubectl get sparkapplication spark-wordcount
```

### Step 7: Create Documentation
**File**: `/Users/hzy/projects/k8s/spark/spark-operator/my-example/README.md`

**Sections to Include**:
1. **Overview** - What this example demonstrates
2. **Prerequisites** - Docker, kubectl, Spark Operator installed
3. **Quick Start** - Build and deploy in 3 commands
4. **File Structure** - Explanation of each file
5. **Building the Image** - Step-by-step build instructions
6. **Deploying to Kubernetes** - Deployment process
7. **Viewing Results** - How to check status and logs
8. **Customization** - Using your own data, adding dependencies, cloud storage
9. **Troubleshooting** - Common issues and solutions
10. **Next Steps** - Ideas for extending the application

## Critical Technical Decisions

### Docker Image Strategy
- **Minimal extension** of official `apache/spark:4.0.0`
- Include application code and sample data in image
- No additional Python packages initially (extensible later)
- Fast build times, small image size

### Output Location
- Use `/tmp/wordcount-output` initially (no PVC required)
- Easy to verify in logs
- Can be changed to PVC or cloud storage later

### Security
- Reuse all security settings from `spark-pi.yaml`
- Production-grade security out of the box
- No privilege escalation, non-root user, minimal capabilities

### Resource Allocation
- Conservative defaults from `spark-pi.yaml`
- 2 executors with 100m CPU request, 500m limit
- Works on resource-constrained clusters

## Testing & Validation

**Before Kubernetes Deployment**:
1. Verify Docker image builds successfully
2. Check image size (should be < 1GB)
3. Validate YAML syntax

**After Kubernetes Deployment**:
1. Monitor SparkApplication status: `kubectl get sparkapplication spark-wordcount`
2. View driver logs: `kubectl logs -f spark-wordcount-driver`
3. Verify application reaches COMPLETED state
4. Check word count results in logs (top 20 words)

## Success Criteria
- ✓ Docker image builds without errors
- ✓ Application deploys successfully via kubectl
- ✓ SparkApplication reaches COMPLETED state
- ✓ Word count results are correct and visible in logs
- ✓ All security contexts are enforced
- ✓ Documentation is clear and actionable

## Extension Points (Future)
- Add Python dependencies (pandas, numpy, etc.)
- Integrate cloud storage (S3, GCS, Azure)
- Add PersistentVolume for output
- Implement more complex PySpark applications
- Set up CI/CD pipeline

## Files to Create (in order)
1. `app/wordcount.py` - Core application
2. `data/sample-text.txt` - Test data
3. `Dockerfile` - Container packaging
4. `build.sh` - Build automation
5. `spark-wordcount.yaml` - Kubernetes deployment
6. `deploy.sh` - Deployment automation
7. `README.md` - Documentation
