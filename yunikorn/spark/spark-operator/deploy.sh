#!/bin/bash
# Deployment script for Spark Word Count Application

set -e

# Configuration
YAML_FILE="spark-wordcount.yaml"
APP_NAME="spark-wordcount"
NAMESPACE="default"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Deploying Spark Word Count Application...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check kubectl connectivity
echo -e "\n${BLUE}Checking Kubernetes connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    echo "Please check your kubeconfig and cluster connection"
    exit 1
fi

# Check if Spark Operator is installed
echo -e "\n${BLUE}Checking if Spark Operator is installed...${NC}"
if ! kubectl get crd sparkapplications.sparkoperator.k8s.io &> /dev/null; then
    echo -e "${YELLOW}Warning: SparkApplication CRD not found${NC}"
    echo "Please ensure the Spark Operator is installed in your cluster"
    echo "Visit: https://github.com/kubeflow/spark-operator"
    exit 1
fi

# Check if service account exists
echo -e "\n${BLUE}Checking service account...${NC}"
if ! kubectl get serviceaccount spark-operator-spark -n ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}Warning: ServiceAccount 'spark-operator-spark' not found in namespace ${NAMESPACE}${NC}"
    echo "The application may fail to start without proper RBAC configuration"
    echo "Do you want to continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Delete existing application if it exists
if kubectl get sparkapplication ${APP_NAME} -n ${NAMESPACE} &> /dev/null; then
    echo -e "\n${YELLOW}Existing SparkApplication '${APP_NAME}' found. Deleting...${NC}"
    kubectl delete sparkapplication ${APP_NAME} -n ${NAMESPACE}
    echo "Waiting for cleanup..."
    sleep 5
fi

# Apply the SparkApplication
echo -e "\n${BLUE}Applying SparkApplication from ${YAML_FILE}...${NC}"
kubectl apply -f ${YAML_FILE}

# Wait a moment for the application to initialize
echo -e "\n${BLUE}Waiting for application to start...${NC}"
sleep 3

# Show application status
echo -e "\n${GREEN}Deployment initiated successfully!${NC}"
echo -e "\n${BLUE}Application Status:${NC}"
kubectl get sparkapplication ${APP_NAME} -n ${NAMESPACE}

# Show driver pod status if it exists
echo -e "\n${BLUE}Driver Pod Status:${NC}"
if kubectl get pod ${APP_NAME}-driver -n ${NAMESPACE} &> /dev/null; then
    kubectl get pod ${APP_NAME}-driver -n ${NAMESPACE}
else
    echo "Driver pod not yet created (this is normal, wait a few seconds)"
fi

# Provide monitoring commands
echo -e "\n${BLUE}Monitoring Commands:${NC}"
echo "----------------------------------------"
echo "Watch application status:"
echo "  kubectl get sparkapplication ${APP_NAME} -n ${NAMESPACE} -w"
echo ""
echo "View driver logs:"
echo "  kubectl logs -f ${APP_NAME}-driver -n ${NAMESPACE}"
echo ""
echo "View all pods:"
echo "  kubectl get pods -n ${NAMESPACE} | grep ${APP_NAME}"
echo ""
echo "View executor logs (after executors start):"
echo "  kubectl logs ${APP_NAME}-exec-1 -n ${NAMESPACE}"
echo ""
echo "Describe application (for debugging):"
echo "  kubectl describe sparkapplication ${APP_NAME} -n ${NAMESPACE}"
echo ""
echo "Delete application:"
echo "  kubectl delete sparkapplication ${APP_NAME} -n ${NAMESPACE}"
echo "----------------------------------------"

echo -e "\n${GREEN}Tip: The application should complete in a few minutes.${NC}"
echo -e "${GREEN}Check the driver logs to see the word count results!${NC}"
