# Setup Redpanda on k3s

Scripts to setup the [Redpanda](https://redpanda.com) dev cluster on a developer laptop using [k3d](https:/k3d.io).

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

### rpk Profile

`rpk` profile is convinent way to switch Redpanda settings for different cluster environment. Let us setup one for `k3s` setup

```shell
rpk profile create k3s
```

Now let use make the profile use the `brokers` using the exposed address `localhost:31092`

```shell
rpk profile set brokers localhost:31092
```

Now running the command to display the cluster status,

```shell
rpk cluster status
```

Should show the an output like

```text
CLUSTER
=======
redpanda.58b01085-1072-4ea1-8225-78fcc18238a5

BROKERS
=======
ID    HOST                  PORT
0*    redpanda-0.localhost  31092

TOPICS
======
NAME      PARTITIONS  REPLICAS
_schemas  1           1
```

### List Topics

```shell
rpk topic list
```

Should show the following output,

```shell
NAME      PARTITIONS  REPLICAS
_schemas  1           1
```

Let us try creating a new topic,

```shell
rpk topic create greetings
```

The command should fail with following error,

```text
unable to create topics [greetings]: unable to dial: dial tcp: lookup redpanda-0.localhost: no such host
```

### Resolving `.localhost` domains

We don't have a resolver to route our requests to `redpanda-0.localhost`. There are many ways to do it and very simple of all is to add an entry to `/etc/hosts` file. But to make it more clean and neat, with ability to support other domain names than `.localhost` we will use [dnsmasq](https://dnsmasq.org).

Run the following command to install `dnsmasq`

```shell
brew install dnsmasq
```

Configure the DNS server on `12.0.0.1` and make `.localhost` to be resolved using that DNS server,

```shell
echo 'address=/.localhost/127.0.0.1' >> "$(brew --prefix)/etc/dnsmasq.conf"
echo 'listen-address=127.0.0.1' >> "$(brew --prefix)/etc/dnsmasq.conf"
```

Restart the `dnsmasq` service,

```shell
sudo brew services restart dnsmasq
```

Add a resolver to be used by dnsmaq to resolve `.localhost`,

```shell
sudo mkdir -pv /etc/resolver
echo 'nameserver 127.0.0.1' | sudo tee -a /etc/resolver/localhost
```

Now when you try to ping the Redpanda broker address `redpanda-0.localhost` it should be reachable,

```shell
ping -c3 redpanda-0.localhost
```

Should output

```text
PING redpanda-0.localhost (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.053 ms
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.092 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.058 ms
```

Now we are all set to create new topics using the command,

```shell
rpk topic create greetings
```

Which should return,

```shell
TOPIC      STATUS
greetings  OK
```

## Cleanup

```shell
./destroy.sh
```
