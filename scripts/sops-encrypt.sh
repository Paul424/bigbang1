#!/bin/bash
set -euxo pipefail

sops --encrypt environments/base/common-bb-secret.yaml > environments/base/common-bb-secret.enc.yaml
sops --encrypt environments/dev/secrets/dev-bb-secret.yaml > environments/dev/secrets/dev-bb-secret.enc.yaml
