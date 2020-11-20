# Spring cloud vault integration
## Spring configs
By default spring will use version 1 of vault key value, to use version 2 only we need to add these lines in bootstrap.yml:
```
spring.cloud.vault:
    generic:
        enabled: false
      kv:
        enabled: true    
```
With the above setup, spring cloud vault will look into these path:
```
/secret/{application}/{profile}
/secret/{application}
/secret/{default-context}/{profile}
/secret/{default-context}
```
If the backend path is different from `secret`, we need to set backend prop like so:
```
spring.cloud.vault:
      generic:
        enabled: false
      kv:
        enabled: true
        backend: some_other_path
```
This will let spring to look into these paths :
```
/{backend}/{application}/{profile}
/{backend}/{application}
/{backend}/{default-context}/{profile}
/{backend}/{default-context}
```
Behind the scene, spring actually makes a request to `/{backend}/data` instead of `/{backend}`, which is the actual mount path for kv version 2.   

Note: `generic` (version 1) is enabled by default, even if we only specify `kv` (version 2). This can cause the issue with Spring looking into `/secret` paths for `generic`:
```
/secret/{application}/{profile}
/secret/{application}
/secret/{default-context}/{profile}
/secret/{default-context}
```
If the paths are not available or not accessible by the policy attached to the role, we will get 403 response. We need to explicitly disable `generic` key value.   

A complete example with spring cloud vault using Kubernetes method using custom path:
```
spring:
  application:
    name: app-name
  cloud:
    vault:
      generic:
        enabled: false
      kv:
        enabled: true
        backend: some_other_path
      authentication: KUBERNETES
      kubernetes:
        role: vault-demo
        kubernetes-path: kubernetes/dc12-dev-01/vault-demo-dev-vault-auth
        service-account-token-file: /var/run/secrets/kubernetes.io/serviceaccount/token
      namespace: namespace-name
      host: localhost
      port: 8200
      scheme: https
      fail-fast: true
      uri: https://localhost:8200
      connection-timeout: 5000
      read-timeout: 15000
      enabled: true
```
Given the active profile is `dev`, spring will look into these vault paths (in order) in `namespace-name` namespace to retrieve secrets (list of key-value pairs):
```
/some_other_path/app-name/dev
/some_other_path/app-name
```
## Debugging
To add more debug logs, enable log level with spring configs in environment variable or application.yml:
```
logging.level.org.springframework.web=DEBUG
```
## References:
- https://github.com/spring-cloud/spring-cloud-vault/issues/279
- https://cloud.spring.io/spring-cloud-vault/multi/multi_vault.config.backends.html#vault.config.backends.kv.versioned
- https://stackoverflow.com/questions/55226030/spring-cloud-vault-with-k2-v2-how-to-avoid-403-at-startup