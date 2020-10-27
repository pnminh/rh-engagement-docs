# Vault integration with Openshift Applications
## Using Vault agent and Consul templates
This approach allows the integration to be framework agnostic. Vault agent can be run as a sidecar or init container and feed the main application with credentials retrieved from the Vault server.   

### Set up Vault agent with Kubernetes auth method
Enable kubernetes auth method (logged in as okta user, check Log in as okta user section) and set up a token verifier account. This account will validate the token sent from the vault agent running on Openshift with the Openshift API server before allowing that vault agent to retrieve the data from Vault server. 

```
$ vault auth list -namespace VAULT_NAMESPACE
Path        Type        Accessor                  Description
----        ----        --------                  -----------
approle/    approle     auth_approle_d0988d5c     n/a
token/      ns_token    auth_ns_token_988a8132    token based credentials

$ vault auth enable  -namespace VAULT_NAMESPACE kubernetes
Success! Enabled kubernetes auth method at: kubernetes/

$ vault auth list -namespace VAULT_NAMESPACE
Path           Type          Accessor                    Description
----           ----          --------                    -----------
approle/       approle       auth_approle_d0988d5c       n/a
kubernetes/    kubernetes    auth_kubernetes_00c30869    n/a
token/         ns_token      auth_ns_token_988a8132      token based credentials
$ vault write -namespace VAULT_NAMESPACE auth/kubernetes/config token_reviewer_jwt="$VAULT_AUTH_SA_TOKEN" kubernetes_host=${OPENSHIFT_API_URL} kubernetes_ca_cert=@ca.crt
Success! Data written to: auth/kubernetes/config
```
Note:  The token and the file ca.crt have to be from the service account (on Openshift go to User Management > Service Accounts > ServiceAccount name > Secrets > [SA_NAME]_token_xxxx that has token reviewer access. To achieve that, a cluster role named system:auth-delegator needs to be assigned to the service account. This can only be run by cluster-admin role:
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault-auth
    namespace: NAMESPACE
```
Create a named role for the vault agent service account(not necessarily vault-auth in this example but any  that the vault agent will use):
```
$ vault write -namespace VAULT_NAMESPACE auth/kubernetes/role/default bound_service_account_names=vault-auth bound_service_account_namespaces=OPENSHIFT_NAMESPACE policies=default
```
On the app deployment side, make sure the deployment config has Vault agent and Consul template to run as sidecar/init container and the service account is created and assigned to the vault agent sidecar/init container:
```
kind: DeploymentConfig
apiVersion: apps.openshift.io/v1
metadata:
  name: app-with-vault-agent-dc
  namespace: OPENSHIFT_NAMESPACE
  labels:
    app: app-with-vault-agent-dc
spec:
  strategy:
    type: Rolling
    rollingParams:
      updatePeriodSeconds: 1
      intervalSeconds: 1
      timeoutSeconds: 600
      maxUnavailable: 25%
      maxSurge: 25%
    resources: {}
    activeDeadlineSeconds: 21600
  triggers:
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
          - APP_NAME
        from:
          kind: ImageStreamTag
          namespace: OPENSHIFT_NAMESPACE
          name: 'APP_NAME:latest'
    - type: ConfigChange
  replicas: 1
  revisionHistoryLimit: 10
  test: false
  selector:
    name: app-with-vault-agent-dc
  template:
    metadata:
      creationTimestamp: null
      labels:
        name: app-with-vault-agent-dc
    spec:
      restartPolicy: Always
      initContainers:
        - resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 100m
              memory: 128Mi
          terminationMessagePath: /dev/termination-log
          name: vault-agent-auth
          env:
            - name: VAULT_ADDR
              value: 'https://VAULT_SERVER:8200'
            - name: SKIP_CHOWN
              value: 'true'
            - name: SKIP_SETCAP
              value: 'true'
            - name: VAULT_SKIP_VERIFY
              value: 'true'
          imagePullPolicy: Always
          volumeMounts:
            - name: vault-config
              mountPath: /etc/vault
            - name: vault-token
              mountPath: /home/vault
          terminationMessagePolicy: File
          image: docker.io/library/vault:latest'
          args:
            - agent
            - '-config=/etc/vault/vault-agent-config.hcl'
        - resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 100m
              memory: 128Mi
          terminationMessagePath: /dev/termination-log
          name: consul-template
          env:
            - name: VAULT_ADDR
              value: 'https://VAULT_SERVER:8200'
            - name: VAULT_SKIP_VERIFY
              value: 'true'
          imagePullPolicy: Always
          volumeMounts:
            - name: vault-token
              mountPath: /home/vault
            - name: vault-config
              mountPath: /etc/consul-template
            - name: vault-secrets
              mountPath: /etc/secrets
          terminationMessagePolicy: File
          image: 'hashicorp/consul-template:latest'
          args:
            - '-config=/etc/consul-template/consul-template-config.hcl'
            - '-once'
      serviceAccountName: vault-auth
      schedulerName: default-scheduler
      terminationGracePeriodSeconds: 30
      securityContext: {}
      containers:
        - resources:
            limits:
              cpu: 350m
              memory: 700Mi
            requests:
              cpu: 30m
              memory: 200Mi
          terminationMessagePath: /dev/termination-log
          name: APP_NAME
          env:
            - name: VAULT_NAMESPACE
              value: VAULT_NAMESPACE
            - name: _JAVA_OPTIONS
              value: '-Xms512m -Xmx1152m'
          securityContext:
            capabilities: {}
            privileged: false
          ports:
            - containerPort: 8080
              protocol: TCP
            - containerPort: 8443
              protocol: TCP
            - containerPort: 8778
              protocol: TCP
          imagePullPolicy: Always
          volumeMounts:
            - name: vault-secrets
              mountPath: /home/jboss/vault_mount
          terminationMessagePolicy: File
          image: >-
            docker.io/APP_NAME:latest
      serviceAccount: vault-auth
      volumes:
        - name: vault-token
          emptyDir:
            medium: Memory
        - name: vault-secrets
          emptyDir:
            medium: Memory
        - name: vault-config
          configMap:
            name: vault-auth-config
            items:
              - key: vault-agent-config.hcl
                path: vault-agent-config.hcl
              - key: consul-template-config.hcl
                path: consul-template-config.hcl
            defaultMode: 420
      dnsPolicy: ClusterFirst
```
We also need to create a configMap that has the consul template. This template will have all placeholders to be replaced data from Vault server and provided to the main container on startup.
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: vault-auth-config
  namespace: vt-eld-server-dev
data:
  consul-template-config.hcl: |
    vault {
      namespace = "VAULT_NAMESPACE"
      renew_token = false
      vault_agent_token_file = "/home/vault/.vault-token"
      retry {
        backoff = "1s"
      }
    }

    template {
    destination = "/etc/secrets/application.properties"
    contents = <<EOH
    {{- with secret "db/aurora_creds" }}
    ###############################################################################
    ## HikariCP (Connection Pools)
    ###############################################################################
    hikari.analytics.poolName=analytics
    hikari.analytics.jdbcUrl=jdbc:postgresql://aurora-cluster-one.cqpv6ge7diee.us-west-2.rds.amazonaws.com/postgres
    hikari.analytics.username=postgres
    hikari.analytics.password={{ index .Data.data "aurora_password" }}
    hikari.analytics.maximumPoolSize=5
    hikari.analytics.minimumIdle=1
    {{ end }}
    EOH
    }
  vault-agent-config.hcl: |-
    exit_after_auth = true
    pid_file = "/home/vault/pidfile"

    auto_auth {
      method "kubernetes" {
        namespace = "VAULT_NAMESPACE"
        mount_path = "auth/kubernetes"
        config = {
          role = "default"
        }
      }

      sink "file" {
        config = {
          path = "/home/vault/.vault-token"
        }
      }
    }

```


From the example above, we use `{{- with secret "db/aurora_creds" }}` to get the secrets under the Vault path `db/aurora_creds`.  We then can replace the placeholder `hikari.master.password={{ index .Data.data "aurora_password"}}` with the secret value at runtime.

Note: To use the vault image on Openshift without anyuid scc, we need to add these 2 environment variables 
```
SKIP_CHOWN=true
SKIP_SETCAP=true
```