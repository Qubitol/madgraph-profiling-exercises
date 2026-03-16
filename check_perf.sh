#!/bin/bash
set -e
echo "=== Checking perf availability ==="
if ! command -v perf &> /dev/null; then
    echo "ERROR: perf not found in PATH"
    exit 1
fi
echo "perf binary: $(which perf)"
perf --version
echo ""
echo "=== Testing perf stat ==="
if perf stat -e cycles ls /tmp > /dev/null 2>&1; then
    echo "OK: perf stat works"
else
    echo "ERROR: perf stat failed."
    echo "Make sure you started the container with --privileged"
    echo "Also ensure the HOST has: sudo sysctl kernel.perf_event_paranoid=-1"
    exit 1
fi
echo ""
echo "=== Testing perf record ==="
if perf record -o /tmp/perf_test.data -g -- ls /tmp > /dev/null 2>&1; then
    echo "OK: perf record works"
    rm -f /tmp/perf_test.data
else
    echo "ERROR: perf record failed."
    echo "Make sure you started the container with --privileged"
    exit 1
fi
echo ""
echo "=== All checks passed ==="
