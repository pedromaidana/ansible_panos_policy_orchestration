#!/bin/bash
# Build script for PAN-OS Policy Automation Execution Environment
#
# This script builds a custom AWX execution environment with all required dependencies
# for the paloaltonetworks.panos_policy_automation collection

set -e

# Configuration - UPDATE THESE VALUES
REGISTRY="quay.io"
USERNAME="${REGISTRY_USERNAME:-your-username}"  # Set via env var or change this
IMAGE_NAME="panos-policy-ee"
VERSION="${EE_VERSION:-1.0.0}"
FULL_IMAGE="${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${VERSION}"

echo "=========================================="
echo "Building PAN-OS Policy Execution Environment"
echo "=========================================="
echo "Image: ${FULL_IMAGE}"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v ansible-builder &> /dev/null; then
    echo "ERROR: ansible-builder not found. Install with: pip install ansible-builder"
    exit 1
fi

if ! command -v podman &> /dev/null && ! command -v docker &> /dev/null; then
    echo "ERROR: Neither podman nor docker found. Please install one of them."
    exit 1
fi

# Determine container runtime
if command -v podman &> /dev/null; then
    CONTAINER_RUNTIME="podman"
else
    CONTAINER_RUNTIME="docker"
fi
echo "Using container runtime: ${CONTAINER_RUNTIME}"

# Build the execution environment
echo ""
echo "Building execution environment..."
ansible-builder build \
    --tag "${FULL_IMAGE}" \
    --container-runtime "${CONTAINER_RUNTIME}" \
    --verbosity 3

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo "Image: ${FULL_IMAGE}"
echo ""
echo "Next steps:"
echo "  1. Push to registry:"
echo "     ${CONTAINER_RUNTIME} push ${FULL_IMAGE}"
echo ""
echo "  2. In AWX, add this Execution Environment:"
echo "     - Name: PAN-OS Policy EE"
echo "     - Image: ${FULL_IMAGE}"
echo "     - Pull: Always"
echo ""
echo "  3. Update your Job Template to use this EE"
echo "=========================================="
