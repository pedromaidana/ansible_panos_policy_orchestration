# AWX/Ansible Automation Platform Setup Guide

This guide explains how to set up this collection in AWX or Ansible Automation Platform (AAP).

## Problem

When running this collection in AWX, you may encounter this error:
```
"msg": "Missing required library \"pan-python\"."
```

This happens because the default AWX execution environments don't include the Python libraries required by the `paloaltonetworks.panos` collection.

## Solution: Custom Execution Environment

You need to build a **custom execution environment** (container image) that includes all required dependencies.

---

## Option 1: Build Custom Execution Environment (Recommended)

### Prerequisites

On your build machine (can be your laptop or CI/CD system):

1. Install Python 3.9+
2. Install ansible-builder:
   ```bash
   pip install ansible-builder
   ```
3. Install a container runtime:
   - **Podman** (recommended): `brew install podman` (macOS) or package manager
   - **Docker**: Install from docker.com

4. Access to a container registry:
   - **Quay.io** (recommended, free for public images)
   - **Docker Hub**
   - **Private registry** (Harbor, Artifactory, etc.)

### Step 1: Build the Execution Environment

1. Clone/download this repository
2. Edit `build-ee.sh` and update:
   ```bash
   REGISTRY="quay.io"
   USERNAME="your-quay-username"  # Your registry username
   ```

3. Make the script executable and run it:
   ```bash
   chmod +x build-ee.sh
   ./build-ee.sh
   ```

   Or build manually:
   ```bash
   ansible-builder build -t quay.io/your-username/panos-policy-ee:1.0.0 -v 3
   ```

### Step 2: Push to Container Registry

1. Login to your registry:
   ```bash
   # For Quay.io
   podman login quay.io

   # For Docker Hub
   podman login docker.io
   ```

2. Push the image:
   ```bash
   podman push quay.io/your-username/panos-policy-ee:1.0.0
   ```

3. **Make it public** (if using Quay.io):
   - Go to quay.io → Your repository
   - Settings → Make Public

### Step 3: Configure AWX to Use the Custom EE

1. **Add Execution Environment in AWX:**
   - Navigate to: **Administration** → **Execution Environments**
   - Click **Add**
   - Fill in:
     - **Name**: `PAN-OS Policy EE`
     - **Image**: `quay.io/your-username/panos-policy-ee:1.0.0`
     - **Pull**: `Always` (or `Only if not present`)
   - Click **Save**

2. **Update Your Job Template:**
   - Go to: **Templates** → [Your Job Template]
   - Change **Execution Environment** to: `PAN-OS Policy EE`
   - **Uncheck** "Enable Requirement(s) Download" (dependencies are now in the image)
   - **Keep checked** "Enable Collection(s) Download" (if you want latest collections)
   - Click **Save**

3. **Run Your Job:**
   - The Python dependencies should now be available
   - The error should be resolved

---

## Option 2: Use Pre-built Execution Environment (If Available)

If someone in your organization has already built the EE:

1. Get the image name from them (e.g., `registry.company.com/panos-ee:1.0.0`)
2. In AWX: **Administration** → **Execution Environments** → **Add**
3. Add image details and credentials if needed
4. Update your Job Template to use it

---

## Option 3: Manual Dockerfile (Alternative)

If you prefer to build with Docker/Podman directly without ansible-builder:

1. Create this `Dockerfile`:
   ```dockerfile
   FROM quay.io/ansible/ansible-runner:latest

   # Install system dependencies
   USER root
   RUN yum -y install python3-devel gcc git libxml2-devel libxslt-devel && yum clean all

   # Install Python dependencies
   COPY requirements.txt /tmp/requirements.txt
   RUN pip3 install --upgrade pip setuptools wheel && \
       pip3 install -r /tmp/requirements.txt

   # Install Ansible collections
   COPY collections/requirements.yml /tmp/requirements.yml
   RUN ansible-galaxy collection install -r /tmp/requirements.yml

   USER 1000
   ```

2. Build and push:
   ```bash
   podman build -t quay.io/your-username/panos-policy-ee:1.0.0 .
   podman push quay.io/your-username/panos-policy-ee:1.0.0
   ```

---

## Verification

After configuring AWX with the custom EE, run this test playbook:

```yaml
---
- hosts: localhost
  gather_facts: false
  tasks:
    - name: Verify pan-python is installed
      ansible.builtin.command: python3 -c "import pan.xapi; print('pan-python OK')"
      changed_when: false

    - name: Verify pandevice is installed
      ansible.builtin.command: python3 -c "import pandevice; print('pandevice OK')"
      changed_when: false
```

If both tasks succeed, your EE is configured correctly.

---

## Troubleshooting

### Build Fails

**Error: `ansible-builder: command not found`**
- Solution: `pip install ansible-builder`

**Error: Container runtime not found**
- Solution: Install podman or docker

**Error: Permission denied**
- Solution: Add user to docker/podman group or run with `sudo`

### AWX Can't Pull Image

**Error: `pull access denied`**
- Solution: Make image public, or add registry credentials in AWX
- In AWX: **Administration** → **Credentials** → Add Container Registry credential

**Error: `manifest unknown`**
- Solution: Verify image was pushed successfully: `podman search quay.io/your-username/panos-policy-ee`

### Still Getting "Missing pan-python" Error

1. Verify the EE is selected in Job Template
2. Check job output shows correct EE image being used
3. Try forcing a fresh pull: Set Pull to "Always" in EE settings
4. Rebuild the EE and push again

---

## Project Configuration Summary

For AWX to work properly with this collection:

### Required Files (in Git repository):
- ✅ `collections/requirements.yml` - Ansible collections
- ✅ `requirements.txt` - Python dependencies
- ✅ `execution-environment.yml` - EE build definition
- ✅ `inventory.yml` - Your inventory
- ✅ Playbooks and roles

### AWX Project Settings:
- **SCM Type**: Git
- **SCM URL**: Your repository URL
- **SCM Branch**: master (or your branch)
- **Options**: ✓ Update Revision on Launch

### AWX Job Template Settings:
- **Inventory**: Your inventory
- **Project**: Your project
- **Playbook**: Your playbook file
- **Execution Environment**: Your custom PAN-OS EE
- **Credentials**: Your PAN-OS/network credentials
- **Options**: ✓ Enable Collection(s) Download (optional)

### Environment Variables (Credentials):
Set these in AWX Credentials or Extra Vars:
- `ANSIBLE_NET_USERNAME`: PAN-OS username
- `ANSIBLE_NET_PASSWORD`: PAN-OS password

---

## Why This Is Necessary

AWX runs playbooks inside **containerized execution environments** with read-only filesystems. Unlike traditional Ansible:

- ❌ Can't `pip install` at runtime
- ❌ Can't write to system Python directories
- ✅ Must have dependencies pre-installed in the container image

This is by design for:
- Security (immutable environments)
- Reproducibility (same image = same results)
- Isolation (no side effects between jobs)

---

## Updates and Maintenance

When you update collections or add new Python dependencies:

1. Update `requirements.txt` or `collections/requirements.yml`
2. Rebuild the EE with a new version tag:
   ```bash
   EE_VERSION=1.1.0 ./build-ee.sh
   ```
3. Push the new version
4. Update the EE in AWX to point to the new version
5. Test before rolling out to production

---

## Resources

- [Ansible Builder Documentation](https://ansible-builder.readthedocs.io/)
- [AWX Execution Environments Guide](https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html)
- [Quay.io Container Registry](https://quay.io/)
- [PAN-OS Ansible Collection](https://galaxy.ansible.com/paloaltonetworks/panos)
