#!/usr/bin/env bash
# PyTorch verification: version, CUDA availability, cuDNN, device, and a real
# GPU matmul. Run inside the activated 'cuda133' virtualenv.
# See docs/07-verification.md
set -euo pipefail

echo ">> torch version:"
python -c "import torch; print(torch.__version__)"

echo ">> CUDA available:"
python -c "import torch; print(torch.cuda.is_available())"

echo ">> cuDNN enabled / version:"
python -c "import torch; print(torch.backends.cudnn.enabled); print(torch.backends.cudnn.version())"

echo ">> Device name / current allocation:"
python -c "import torch; print(torch.cuda.get_device_name(0)); print(torch.cuda.memory_allocated())"

echo ">> Real GPU matmul:"
python - <<'PY'
import torch
a = torch.rand(1000, 1000).cuda()
b = torch.rand(1000, 1000).cuda()
c = torch.matmul(a, b)
print('matmul OK, shape:', c.shape)
PY

echo ">> All checks passed."
