# Secrets Management using SOPS

## Prerequisites

### Tools

1. [install sops](https://github.com/getsops/sops/releases)
2. [fluxcli](https://fluxcd.io/flux/cmd/)

## SOPS setup

### Generate a new gpg key (first time only)

```
gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: "flux secrets"
Name-Real: "dev.bigbang.mil"
EOF

FP=$(gpg --fingerprint --with-colons "dev.bigbang.mil" | awk -F: '/^fpr:/ { print $10; exit }')
if [ -z "$FP" ]; then
    echo "Fingerprint not found"
    exit 1
else
    echo "Fingerprint: $FP"
fi

# Set the finger-print in the .sops.yaml config.
sed -i "s/pgp: .*/pgp: ${FP}/" .sops.yaml
```

### Share an existing gpg key

To share an existing gpg key with another machine:

1. Export the gpg key
```
gpg --list-secret-keys --keyid-format LONG  --armor "dev.bigbang.mil"
sec   rsa4096/A3BBB35300426AFC 2026-07-03 [SCEAR]
      E1D67B702BB9F292D18083D2A3BBB35300426AFC
uid                 [ultimate] "dev.bigbang.mil" ("flux secrets")
ssb   rsa4096/C26BD25FE1F0387A 2026-07-03 [SEA]

gpg --export-secret-key -a dev.bigbang.mil > ./asc/dev-bigbang-mil.asc
```

2. Copy the file to the new environment

3. Import the gpg key
```
gpg --import dev-bigbang-mil.asc
```

For convenience only the key is [committed to this repository](../asc/dev-bigbang-mil.asc), obviously in a real-world-project the key needs to be shared securely within the team.

### Apply the key to the cluster

```
gpg --export-secret-key --armor "dev.bigbang.mil" | kubectl create secret generic sops-gpg -n bigbang --from-file=key.asc=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
```

## SOPS Wow

1. Decrypt secrets

```
sops --decrypt environments/base/common-bb-secret.enc.yaml > environments/base/common-bb-secret.yaml
```

2. Edit....
```
code environments/base/common-bb-secret.yaml
```

3. Encrypt secrets
```
sops --encrypt environments/base/common-bb-secret.yaml > environments/base/common-bb-secret.enc.yaml
sops --encrypt environments/dev/secrets/dev-bb-secret.yaml > environments/dev/secrets/dev-bb-secret.enc.yaml
```
