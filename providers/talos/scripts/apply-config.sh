#!/bin/bash
# set -euxo pipefail
set -x

#!/bin/bash
# set -euxo pipefail
set -x

if [ "$1" == "--insecure" ]; then
  export CTL1_IP=192.168.50.180
  export CTL2_IP=192.168.50.181
  export CTL3_IP=192.168.50.182
  export WRK1_IP=192.168.50.183
  export WRK2_IP=192.168.50.184
  export WRK3_IP=192.168.50.185
  export WRK4_IP=192.168.50.186
  export WRK5_IP=192.168.50.187
  export WRK6_IP=192.168.50.188
  export AI1_IP=192.168.50.189
else
  export CTL1_IP=192.168.20.10
  export CTL2_IP=192.168.20.11
  export CTL3_IP=192.168.20.12
  export WRK1_IP=192.168.20.20
  export WRK2_IP=192.168.20.21
  export WRK3_IP=192.168.20.22
  export WRK4_IP=192.168.20.23
  export WRK5_IP=192.168.20.24
  export WRK6_IP=192.168.20.25
  export AI1_IP=192.168.20.26
fi

talosctl apply-config --nodes $CTL1_IP --file ./providers/talos/controlplane.yaml --config-patch @./providers/talos/config-patch-ctl1.yaml "$@" 
talosctl apply-config --nodes $WRK1_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk1.yaml "$@"
talosctl apply-config --nodes $WRK2_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk2.yaml "$@"
talosctl apply-config --nodes $CTL2_IP --file ./providers/talos/controlplane.yaml --config-patch @./providers/talos/config-patch-ctl2.yaml "$@"
talosctl apply-config --nodes $WRK3_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk3.yaml "$@"
talosctl apply-config --nodes $WRK4_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk4.yaml "$@"
talosctl apply-config --nodes $CTL3_IP --file ./providers/talos/controlplane.yaml --config-patch @./providers/talos/config-patch-ctl3.yaml "$@"
talosctl apply-config --nodes $WRK5_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk5.yaml "$@"
talosctl apply-config --nodes $WRK6_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-wrk6.yaml "$@"
talosctl apply-config --nodes $AI1_IP --file ./providers/talos/worker.yaml --config-patch @./providers/talos/config-patch-ai1.yaml "$@"
