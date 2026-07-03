# 07 — Verification

Confirm PyTorch sees CUDA, sees cuDNN, sees your RTX 3050, and can actually run a
GPU kernel. Run these from **inside the `cuda133` virtualenv**.

## Quick checks

```bash
# PyTorch version — expect 2.12.0
python -c "import torch; print(torch.__version__)"

# CUDA available? — expect True
python -c "import torch; print(torch.cuda.is_available())"

# cuDNN enabled + version
python -c "import torch; print(torch.backends.cudnn.enabled); print(torch.backends.cudnn.version())"

# GPU identity + current allocation
python -c "import torch; print(torch.cuda.get_device_name(0)); print(torch.cuda.memory_allocated())"
```

Expected, roughly:

- `2.12.0`
- `True`
- `True` and a cuDNN version integer (e.g. `92200`-ish for 9.22)
- `NVIDIA GeForce RTX 3050` and `0`

## Real GPU work — matmul on device

A version string is not proof the GPU runs. This actually launches a kernel:

```bash
python - <<'PY'
import torch
a = torch.rand(1000, 1000).cuda()
b = torch.rand(1000, 1000).cuda()
c = torch.matmul(a, b)
print('matmul OK, shape:', c.shape)
PY
```

Expected:

```
matmul OK, shape: torch.Size([1000, 1000])
```

If this completes without error, the whole stack — driver, CUDA 13.3, cuDNN 9.22,
and your source-built PyTorch 2.12.0 — is working end to end.

All of the above is bundled in
[`scripts/test-pytorch.sh`](../scripts/test-pytorch.sh):

```bash
./scripts/test-pytorch.sh
```

## If something is off

| Symptom | Likely cause | Where to look |
|---|---|---|
| `torch.cuda.is_available()` is `False` | Driver/toolkit mismatch, or PyTorch built without CUDA | [08-troubleshooting](08-troubleshooting.md) |
| `libcudart.so.13: cannot open shared object file` | `LD_LIBRARY_PATH` / `ldconfig` not set | [09-environment-variables](09-environment-variables.md) |
| cuDNN version prints `None` | cuDNN not found at build time | [04-install-cudnn](04-install-cudnn.md) |
| `double free detected` from any CUDA program | driver ↔ glibc issue | [02-nvidia-beta-drivers](02-nvidia-beta-drivers.md) |

Continue to [Troubleshooting](08-troubleshooting.md) for the deeper diagnoses.
