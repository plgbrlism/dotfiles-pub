#!/usr/bin/env bash
set -euo pipefail

veilad &
DAEMON_PID=$!
trap 'kill "$DAEMON_PID" 2>/dev/null' EXIT

for i in {1..20}; do
    if veila status >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

veila lock --wait-ready

while veila status 2>&1 | grep -i -E '\blocked\b' | grep -v -i "unlocked" >/dev/null; do
    sleep 0.5
done

kill "$DAEMON_PID" 2>/dev/null || true
