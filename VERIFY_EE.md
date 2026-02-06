# Execution Environment Verification

## Quick Test Playbook

Use [list_collections.yml](list_collections.yml) to verify your AWX execution environment has all required dependencies.

### Run in AWX

1. Create a Job Template
2. Select your execution environment
3. Choose playbook: `list_collections.yml`
4. Launch

### Expected Output (Success)

```
TASK [Summary]
ok: [localhost] => {
    "msg": [
        "==========================================",
        "Execution Environment Verification",
        "==========================================",
        "Python: Python 3.9.x",
        "Total packages: XX",
        "pan-python status: OK",
        "pandevice status: OK",
        "=========================================="
    ]
}
```

### What It Checks

- ✅ Python version
- ✅ All installed pip packages
- ✅ PAN-OS specific libraries (pan-python, pandevice, pan-os-python)
- ✅ Ansible collections installed
- ✅ Import verification (confirms libraries actually work)

### If pan-python Status Shows "MISSING"

Your execution environment doesn't have the required dependencies. Build and use the custom EE as described in [AWX_SETUP.md](AWX_SETUP.md).
