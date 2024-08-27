# go-file-server

## Prerequisites

- Helm 3

- Kubernetes 1.20+

## Installing the Chart

```bash
# Add repository
helm repo add go-file-server https://ctxgo.github.io/helm-charts/

# Install chart
helm install my-go-file-server go-file-server/go-file-server --version 1.0.0

```

## Configuration Parameters

### Backend Configuration

#### Image Settings
| Parameter              | Value                     | Description                                           |
|------------------------|---------------------------|-------------------------------------------------------|
| `image.repository`     | ctxgo/go-file-server      | The Docker image repository where the image is stored.|
| `image.tag`            | latest                    | The Docker image tag to be used, specifying the version.|
| `image.pullPolicy`     | IfNotPresent              | The image pull policy, which defines how images are pulled. `IfNotPresent` tells Kubernetes to use the image if already present, otherwise pull it.|

#### Persistence Settings
| Parameter                      | Value           | Description                                           |
|--------------------------------|-----------------|-------------------------------------------------------|
| `persistence.enabled`          | false           | Whether persistence is enabled, allowing for storage to be reused across pod restarts.|
| `persistence.existingClaim`    |                 | The name of an existing Persistent Volume Claim (PVC) to use for storage, if specified.|
| `persistence.accessModes`      | ReadWriteMany   | The permitted access modes for the volume, e.g., `ReadWriteMany` allows multiple nodes to mount the volume for reading and writing.|
| `persistence.size`             | 20Gi            | The size of the requested volume storage.             |
| `persistence.mountPath`        | /basedir        | The path at which the volume is mounted inside the container.|

#### Service Configuration
| Parameter                      | Value           | Description                                           |
|--------------------------------|-----------------|-------------------------------------------------------|
| `service.ports.name`           | http            | The name of the port as defined in the service configuration.|
| `service.ports.containerPort`  | 9090            | The port on the container that the service exposes.   |
| `service.ports.protocol`       | TCP             | The protocol used by the port, TCP is commonly used for HTTP connections.|

#### Resource Requests and Limits
| Parameter                      | Value           | Description                                           |
|--------------------------------|-----------------|-------------------------------------------------------|
| `resources.limits.cpu`         | 500m            | The maximum amount of CPU the container can use.      |
| `resources.limits.memory`      | 1Gi             | The maximum amount of memory the container can use.   |
| `resources.requests.cpu`       | 50m             | The minimum amount of CPU guaranteed to the container.|
| `resources.requests.memory`    | 500Mi           | The minimum amount of memory guaranteed to the container.|

#### Probes
| Parameter                          | Value           | Description                                           |
|------------------------------------|-----------------|-------------------------------------------------------|
| `readinessProbe.initialDelaySeconds` | 10            | The number of seconds after the container starts before the probe is initiated.|
| `readinessProbe.successThreshold`  | 1               | The minimum consecutive successes for the probe to be considered successful after having failed.|
| `readinessProbe.failureThreshold`  | 3               | The number of times the probe will try to fail before giving up.|
| `readinessProbe.timeoutSeconds`    | 10              | The number of seconds after which the probe times out.|
| `readinessProbe.periodSeconds`     | 5               | The frequency in seconds with which to perform the probe.|
| `readinessProbe.tcpSocket.port`    | 9090            | The port on which the probe is performed, using a TCP check.|
| `livenessProbe.initialDelaySeconds` | 10            | The number of seconds after the container starts before the probe is initiated.|
| `livenessProbe.successThreshold`    | 1             | The minimum consecutive successes for the probe to be considered successful after having failed.|
| `livenessProbe.failureThreshold`    | 3             | The number of times the probe will try to fail before giving up.|
| `livenessProbe.timeoutSeconds`      | 10            | The number of seconds after which the probe times out.|
| `livenessProbe.periodSeconds`       | 5             | The frequency in seconds with which to perform the probe.|
| `livenessProbe.tcpSocket.port`      | 9090          | The port on which the probe is performed, using a TCP check.|

#### Environment Variables
| Parameter              | Value         | Description                                           |
|------------------------|---------------|-------------------------------------------------------|
| `env.TZ`               | Asia/Shanghai | The timezone setting for the container, ensuring time-related processes use the correct local time.|

## Ingress Configuration

### Basic Ingress
| Parameter              | Value         | Description                                           |
|------------------------|---------------|-------------------------------------------------------|
| `ingress.enabled`      | false         | Whether ingress is enabled for external access.       |
| `ingress.annotations`  | Various       | Annotations to customize behavior of the ingress controller, like SSL redirect. |
| `ingress.hosts`        | example.com   | The hostname configured for ingress routing.          |
| `ingress.tls`          | example-tls   | The TLS certificate secret name used for HTTPS.       |

### IngressRoute
| Parameter              | Value         | Description                                           |
|------------------------|---------------|-------------------------------------------------------|
| `ingressRoute.enabled` | false         | Whether IngressRoute is enabled for external access using Traefik.|
| `ingressRoute.entryPoints` | web, websecure | Entry points for traffic, distinguishing between HTTP and HTTPS.|
| `ingressRoute.expose`  | Various       | Defines the services and paths to be exposed via IngressRoute.|
| `ingressRoute.tls`     | example-tls   | The TLS certificate secret name for secure connections.|


