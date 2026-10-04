> DO-NOT-COPY as-is.
Why: qtile `.venv/` hardcodes `/home/paul/...`, i3/sway/niri pin `eDP-1`/`HDMI-1` resolution.
Fix before copy: drop `.venv/` + `__pycache__/`, adapt `resolution.conf`/`outputs.kdl`.
