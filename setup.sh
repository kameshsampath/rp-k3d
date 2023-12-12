#!/usr/bin/env bash

set -euo pipefail 

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

export FEATURES_DIR="${DIR}/features"

## Create the Registry
k3d registry create "${CLUSTER_NAME}-registry.localhost"  \
  --port  127.0.0.1:5001 || true

## Create the cluster
k3d cluster create --config "${DIR}/config/k3d/cluster.yml"

while ! kubectl get ns redpanda &>/dev/null
do
  echo "waiting for namespace \"redpanda\" to be created"
  sleep 5s
done

## Wait for the Redpanda Controller to be ready
kubectl --namespace redpanda rollout status --watch deployment/redpanda-operator --timeout=180s
