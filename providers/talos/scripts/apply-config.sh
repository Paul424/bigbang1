#!/bin/bash
# set -euxo pipefail
set -x

talosctl apply-config --nodes $CTL1_IP --file ./providers/talos/controlplane.yaml --config-patch @./providers/talos/config-patch-ctl1.yaml "$@" 
talosctl apply-config --nodes $CTL2_IP --file ./providers/talos/controlplane.yaml --config-patch @./providers/talos/config-patch-ctl2.yaml "$@"
talosctl apply-config --nodes $CTL3_IP --file ./providers/talos/controlplane.yaml --config-patch @./providers/talos/config-patch-ctl3.yaml "$@"
talosctl apply-config --nodes $WRK1_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk1.yaml "$@"
talosctl apply-config --nodes $WRK2_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk2.yaml "$@"
talosctl apply-config --nodes $WRK3_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk3.yaml "$@"
talosctl apply-config --nodes $WRK4_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk4.yaml "$@"
talosctl apply-config --nodes $WRK5_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk5.yaml "$@"
talosctl apply-config --nodes $WRK6_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk6.yaml "$@"
talosctl apply-config --nodes $AI1_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-ai1.yaml "$@"
