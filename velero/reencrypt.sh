#!/bin/bash
SOURCE_FILE="./cloud"
OUT_FILE="sealedsecret_cloud-credentials.yaml"

if test -f $SOURCE_FILE; then
    kubectl -n velero create secret generic cloud-credentials --from-file=$SOURCE_FILE --dry-run=client -o yaml > secret.yaml
    kubeseal --controller-name sealed-secrets <secret.yaml -o yaml >$OUT_FILE
    echo "Created $OUT_FILE"
else
    echo "File '$SOURCE_FILE' not found."
    exit 1
fi