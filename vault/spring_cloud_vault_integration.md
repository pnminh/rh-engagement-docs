# Spring cloud vault integration
## Spring configs
By default spring will use version 1 of vault key value, to use version 2 we need to add these lines:
```
spring.cloud.vault:
    generic:
        enabled: false
```
A complete example with spring cloud vault using Kubernetes method using custom path:
```
spring:
  application:
    name: vistracks
  cloud:
    vault:
      generic:
        enabled: false
      authentication: KUBERNETES
      kubernetes:
        role: vault-demo
        kubernetes-path: kubernetes/dc12-dev-01/vault-demo-dev-vault-auth
        service-account-token-file: /var/run/secrets/kubernetes.io/serviceaccount/token
      namespace: VisTracks
      host: omni-dev-vault.aws.omnitracs.com
      port: 8200
      scheme: https
      fail-fast: true
      uri: https://omni-dev-vault.aws.omnitracs.com:8200
      connection-timeout: 5000
      read-timeout: 15000
      enabled: true
```


## References:
- https://github.com/spring-cloud/spring-cloud-vault/issues/279
- http://cloud.spring.io/spring-cloud-vault/single/spring-cloud-vault.html#vault.config.backends