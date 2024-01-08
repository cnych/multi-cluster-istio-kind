# create-cluster.sh
# This script handles the creation of multiple clusters using kind and the
# ability to create and configure an insecure container registry.

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=util.sh
NUM_CLUSTERS="${NUM_CLUSTERS:-2}"
KIND_IMAGE="${KIND_IMAGE:-}"
KIND_TAG="${KIND_TAG:-v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72}"
OS="$(uname)"


function create-clusters() {
  local num_clusters=${1}

  local image_arg=""
  if [[ "${KIND_IMAGE}" ]]; then
    image_arg="--image=${KIND_IMAGE}"
  elif [[ "${KIND_TAG}" ]]; then
    image_arg="--image=kindest/node:${KIND_TAG}"
  fi
  for i in $(seq "${num_clusters}"); do
    kind create cluster --name "cluster${i}" "${image_arg}"
    fixup-cluster "${i}"
    echo

  done
}

function fixup-cluster() {
  local i=${1} # cluster num

  if [ "$OS" != "Darwin" ];then
    # Set container IP address as kube API endpoint in order for clusters to reach kube API servers in other clusters.
    local docker_ip
    docker_ip=$(docker inspect --format='{{range .NetworkSettingkc s.Networks}}{{.IPAddress}}{{end}}' "cluster${i}-control-plane")
    kubectl config set-cluster "kind-cluster${i}" --server="https://${docker_ip}:6443"
  fi

  # Simplify context name
  kubectl config rename-context "kind-cluster${i}" "cluster${i}"
}


echo "Creating ${NUM_CLUSTERS} clusters"
create-clusters "${NUM_CLUSTERS}"
kubectl config use-context cluster1

echo "Kind CIDR is $(docker network inspect -f '{{$map := index .IPAM.Config 0}}{{index $map "Subnet"}}' kind)"

echo "Complete"