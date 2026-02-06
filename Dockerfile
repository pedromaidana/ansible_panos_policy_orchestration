# Dockerfile for PAN-OS Policy Automation Execution Environment
#
# This is an alternative to using ansible-builder (execution-environment.yml)
# Use this if you prefer to build with Docker/Podman directly
#
# Build:
#   podman build -t quay.io/your-username/panos-policy-ee:1.0.0 .
#
# Push:
#   podman push quay.io/your-username/panos-policy-ee:1.0.0
#
# Use in AWX:
#   Administration → Execution Environments → Add
#   Image: quay.io/your-username/panos-policy-ee:1.0.0

FROM quay.io/ansible/ansible-runner:latest

# Install system dependencies
USER root
RUN yum -y install \
    python3-devel \
    gcc \
    git \
    libxml2-devel \
    libxslt-devel \
    && yum clean all

# Upgrade pip
RUN pip3 install --upgrade pip setuptools wheel

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Install Ansible collections
COPY collections/requirements.yml /tmp/collections-requirements.yml
RUN ansible-galaxy collection install -r /tmp/collections-requirements.yml && \
    rm /tmp/collections-requirements.yml

# Verify installations
RUN echo "=== Verifying Python libraries ===" && \
    python3 -c "import pan.xapi; print('✓ pan-python installed')" && \
    python3 -c "import pandevice; print('✓ pandevice installed')" && \
    echo "=== Verifying Ansible collections ===" && \
    ansible-galaxy collection list | grep paloaltonetworks.panos && \
    echo "=== All dependencies installed successfully ==="

# Switch back to non-root user
USER 1000

LABEL name="panos-policy-ee" \
      description="Execution Environment for PAN-OS Policy Automation" \
      version="1.0.0" \
      maintainer="your-email@example.com"
