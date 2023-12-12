# Setup Redpanda on k3s

Scripts to setup the [Redpanda](https://redpanda.com) dev cluster on a developer laptop using [k3d](https:/k3d.io)

## Required Tools

- [Docker for Desktop](https://www.docker.com/products/docker-desktop/)
- [k3d](https://k3d.io)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

Some optional handy tools

- [yq](https://github.com/mikefarah/yq)
- [direnv](https://direnv.net)

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

The following script creates the [k3s](https://k3s.io)Kubernetes cluster using k3d and deploys the basic single node Redpanda cluster on to it.

```shell
./setup.sh
```

All the manifests in the features are applied on to the cluster via the [cluster.yml](./config/k3d/cluster.yml).

Let us inspect the `redpanda` namespace,

```shell
kubectl get pods,svc -n redpanda
```

Should show an output like,

```text
NAME                                     READY   STATUS      RESTARTS       AGE
pod/redpanda-operator-6659c776dd-r2pdw   2/2     Running     0              2m44s
pod/redpanda-0                           2/2     Running     0              2m23s
pod/redpanda-console-6649f84d9c-h7btb    1/1     Running     1 (113s ago)   2m23s
pod/redpanda-configuration-tl454         0/1     Completed   0              101s

NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                       AGE
service/operator-metrics-service   ClusterIP   10.43.100.13    <none>        8443/TCP                                                      2m44s
service/redpanda                   ClusterIP   None            <none>        9644/TCP,8082/TCP,9093/TCP,33145/TCP,8081/TCP                 2m23s
service/redpanda-console           NodePort    10.43.111.128   <none>        8080:30080/TCP                                                2m23s
service/redpanda-external          NodePort    10.43.214.220   <none>        9645:31644/TCP,9094:31092/TCP,8083:30082/TCP,8084:30081/TCP   2m23s
```

The k3d configuration [cluster.yml](./config/k3d/cluster.yml) has exposed the following `NodePort` to the host interface:

- `Kafka Broker` - localhost:31902
- `Schema Registry` - localhost:30081
- `PandaProxy` - localhost:30082

And the console is accessible using the url <http://localhost:30080/>

## Test the Setup

Inspect the cluster status

```shell
export RPK_BROKERS=localhost:31902
```

```shell
rpk cluster status
```

Should show the an output like

```text
CLUSTER
=======
redpanda.f7dca1bf-7a5d-413b-a570-b60569b1d309

BROKERS
=======
ID    HOST        PORT
0*    redpanda-0  31092

TOPICS
======
NAME      PARTITIONS  REPLICAS
_schemas  1           1
```

## Destroy Cluster

```shell
./destroy.sh
```
