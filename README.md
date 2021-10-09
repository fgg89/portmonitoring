# README

## Node scanner

This script was developed within tight time constraints and lacks proper argument validation. This should be implemented in order to have a robust execution and error handling.

The script may take two optional arguments:

```
-i / interval for report logging
-e / list of comma-separated port numbers to be excluded in the report
```

If no argument is specific, the script will report at a default interval and no whitelisting will take place.


## Kubernetes

### Create namespace

```
kubectl apply -f namespace.yaml
```

### Create secret with creds for dockerhub

```
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=... --docker-password=... --docker-email=... -n portscanner
```

Review the secret:

```
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

### Create daemonset

```
kubectl apply -f portscanner-daemonset.yaml
```

## TODO list of improvements:

* Proper validation of script input arguments
* Make use of AWS Systems Manager to store the password for the docker login


