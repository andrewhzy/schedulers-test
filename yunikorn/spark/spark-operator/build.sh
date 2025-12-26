#!/bin/bash
# Build script for custom Spark Word Count Docker image

set -e

# Configuration
IMAGE_NAME="spark-wordcount"
IMAGE_TAG="latest"
REGISTRY=""  # Set to your registry (e.g., "docker.io/username" or "localhost:5000")

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building Spark Word Count Docker image...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker daemon is not running"
    exit 1
fi

# Build the Docker image
echo -e "\n${BLUE}Building image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Tag for registry if specified
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    echo -e "\n${BLUE}Tagging image for registry: ${FULL_IMAGE_NAME}${NC}"
    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}

    echo -e "\n${GREEN}Image tagged successfully!${NC}"
    echo "To push to registry, run:"
    echo "  docker push ${FULL_IMAGE_NAME}"
fi

# Display image info
echo -e "\n${GREEN}Build completed successfully!${NC}"
echo -e "\n${BLUE}Image details:${NC}"
docker images | grep -E "REPOSITORY|${IMAGE_NAME}"

echo -e "\n${BLUE}Next steps:${NC}"
echo "1. Test the image locally (optional):"
echo "   docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} python /opt/spark/work-dir/wordcount.py --help"
echo ""
echo "2. Update spark-wordcount.yaml with your image name"
if [ -n "$REGISTRY" ]; then
    echo "   spec.image: ${FULL_IMAGE_NAME}"
else
    echo "   spec.image: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "   NOTE: For local testing, also set: imagePullPolicy: Never"
fi
echo ""
echo "3. Deploy to Kubernetes:"
echo "   ./deploy.sh"
