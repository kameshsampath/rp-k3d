# Setup Redpanda on k3s

Scripts to setup the [Redpanda](https://redpanda.com) dev cluster on a developer laptop using [k3d](https:/k3d.io)

## Required Tools

- Docker for Desktop
- k3d
- kubectl

## Environment

The scripts expects the following environment variables to be set,

```shell
# Kubeconfig directory
export KUBECONFIG="$PWD/.kube/config"
# Name of the k3s cluster
export CLUSTER_NAME="redpanda-local"
# number of server nodes
export NUM_SERVERS=1
# number of worker nodes
export NUM_WORKERS=1
# k3s version to deploy
export K3S_VERSION=v1.25.16-k3s4
```

## Create Cluster

The following script creates the cluster and deploys the Redpanda cluster on to it.

```shell
./setup.sh
```

All the manifests in the features are applied on to the cluster via the [cluster.yml](./config/k3d/cluster.yml).

On successful create you should see the following pods on `redpanda` namespace

```shell

```

## Destroy Cluster

```shell
./destroy.sh
```
