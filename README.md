# README

This project was developed for demo purposes in order to implement an agent that scans open ports in EKS cluster nodes and reports the findings to a centralized logging system (AWS Cloudwatch in this scenario). 

The agent has been tested on AWS EKS but could be used in any Kubernetes cluster and Linux-based systems. The agent takes into account open TCP IPv4 ports listening on 0.0.0.0

The solution is containerized and orchestrated via Kubernetes. A DaemonSet makes sure that the agent is executed in every cluster node. The pod in each node consists of two containers: 

* portscanner -- core logic, scans open ports and stores the raw data into a volume.
* [fluentd] (https://www.fluentd.org/) -- sidecar container that has access to the volume where data is stored, parses it and streams it into CloudWatch.

*NOTE: It's recommended to extend the pod with a third container that implements the logic for log rotation. This was out of scope for this project since we do not aim to run it in production systems at this point, but could be a potential development in the future.*

The portscanner docker image is fetched from a private DockerHub repository. A secret was created in Kubernetes for login into this repository and be able to pull the image:

```
# kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=... --docker-password=... --docker-email=... -n portscanner
# kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

In order for the container to have access to the host system network stack, it is necessary to set the ``hostNetwork`` to ``true`` within the DaemonSet spec.

The solution makes use of the following Kubernetes manifests:

* kubernetes/namespace.yaml -- It creates the namespace.
* kubernetes/fluentd_rbac.yaml -- It creates the ClusterRole and ClusterRoleBinding for fluentd and its associated ServiceAccount. It also creates the ConfigMap that will be used by fluentd. 
* kubernetes/portscanner-daemonset.yaml -- DaemonSet that makes sure a pod is running in every cluster node.

Set working namespace as default:

```
kubectl config set-context --current --namespace=portscanner
```

The manifests can be applied by running the following command:

```
kubectl apply -f <MANIFEST.yaml>
```

The ServiceAccount is bound to the following IAM policy in AWS, which grants permissions to operate with CloudWatch Logs:

```
arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

In order to create the ServiceAccount within EKS, the following commands were executed:

```
# eksctl utils associate-iam-oidc-provider --cluster fgonzalez-eks --region us-east-1 --approve
# eksctl create iamserviceaccount --name logging-sa --namespace portscanner --cluster fgonzalez-eks --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy --region us-east-1 --approve
```

## Node scanner

The agent is implemented with a shell script, which can take two optional arguments:

```
portscanner
-i / interval for report logging
-e / list of comma-separated port numbers to be excluded in the report
```

The script returns a list of open ports in the format:

```
[#PORT1, #PORT2, ...]
```

If no argument is specified, the script will report at a default interval (i.e. 60s) and no whitelisting will take place.

fluentd adds the hostname and a count indicating the number of ports. This information will later be used by CloudWatch to create metrics, visualize data and alert.

## Local testing

It is possible to build the image locally via the provided Dockerfile:

```
# docker build -t portscanner .
```

The following command is an example of execution where the interval is overwritten to report every 10s and the ports 22 and 80 are excluded from the report:

```
# docker run portscanner --net=host -i 10 -e 22,80
```

The following command is meant for troubleshooting purposes or if you just want to dive deeper into the container:

```
# docker run -ti --rm --net=host --entrypoint /bin/bash portscanner
```

*NOTE: The script is located at ``/opt/portscanner`` and the log is stored in a volume mounted at ``/var/log/portscanner/portscanner.log``*

## CloudWatch logging, visualization and alerting

Once the logs are streamed into CloudWatch, it is possible to create metric filters in order visualize and/or alert based on those custom metrics.

The following shows a log report sample:

```
2021-10-17T20:21:47.940+02:00  {"message":"[22,111]","hostname":"ip-192-168-0-218.ec2.internal","portscount":2}
```

The logs are streamed by fluentd into a separate CloudWatch loggroup per node. Two metric filters have been configured:

* Metric filter: *has_openports* indicates whether the node has open ports currently or not. The metric contains a dimension for the hostname.
* Metric filter: *portscount* indicates the number of ports that are currently open for the given instance. The metric contains a dimension for the hostname.

In order to have a quick look at both metrics, a dashboard with two widgets has been created in CloudWatch:

![CloudWatch Dashboards](screenshots/cw_dashboard.png)

Additionally, an alarm has also been created in CloudWatch in order to alert if an agent fails to report (i.e. the logstream stops receiving logs).

![Report Alert](screenshots/cw_test_alert.png)

