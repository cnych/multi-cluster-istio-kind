#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail


NUM_CLUSTERS="${NUM_CLUSTERS:-2}"

for i in $(seq "${NUM_CLUSTERS}"); do
  echo "Starting metallb deployment in cluster${i}"
  kubectl apply -f ./metallb-native.yaml --context "cluster${i}"
  kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" --context "cluster${i}"
  kubectl apply -f ./metallb-config-${i}.yaml --context "cluster${i}"
  echo "----"
done