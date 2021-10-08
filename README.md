
## Create secret with creds for dockerhub

```
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=... --docker-password=... --docker-email=...
```

TODO: Use SecretsManager to store the password and retrieve it from K8S

```
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

