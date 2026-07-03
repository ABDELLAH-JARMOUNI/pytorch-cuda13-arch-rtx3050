// Minimal CUDA program: confirms the runtime can see the GPU.
// Build:  nvcc --compiler-bindir /usr/bin/gcc-15 test/test.cu -o /tmp/test
// Run:    /tmp/test          →  expected output: "GPU count: 1"
//
// If this crashes with "free(): double free detected in tcache 2", the problem
// is the CUDA toolkit / driver / glibc layer, NOT PyTorch or gcc.
// See docs/08-troubleshooting.md
#include <stdio.h>

int main() {
    int count;
    cudaGetDeviceCount(&count);
    printf("GPU count: %d\n", count);
    return 0;
}
