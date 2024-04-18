#!/bin/bash
# Stores data from SealedSecrets in vault and creates a corresponding ExternalSecret CRD
# Usage: ./script.sh /path/to/folder/with/secrets (no trailing /)

for secret in $(ls $1/sealedsecret*); do
    echo "Parsing $secret"
    file=$(cat $secret)

    name=$(echo "$file" | yq .metadata.name)
    namespace=$(echo "$file" | yq .metadata.namespace)

    # Create externalsecret yaml
    cat <<EOF > externalsecret_${name}.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: $name
  namespace: $namespace
spec:
  refreshInterval: "15s"
  secretStoreRef:
    name: vault-sa
    kind: ClusterSecretStore
  target:
    name: $name
  data:
EOF

    # Create vault entries of secrets
    json_secret=$(kubectl -n $namespace get secret $name -o json)
    keys=$(echo "$json_secret" | jq -r '.data | keys[]')
    text_blocks=()

    i=0
    for key in $keys; do
        [ "$i" -eq 0 ] && operator=put || operator=patch; ((i++))

        echo ""
        echo "Parsing: $namespace/$name | Key: $key"
        vault kv $operator -mount=secret kubernetes/$name $key="$(echo "$json_secret" | jq ".data.$key" -r | base64 -d)"
        
        # Append to externalsecret
        cat <<-END >>externalsecret_${name}.yaml
  - secretKey: $key
    remoteRef:
      key: kubernetes/$name
      property: $key
END
    done

    echo ""
    echo "------------"
    echo ""
done