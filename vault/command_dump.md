# Commands against vault
## Vault CLI
### app-role method

Enable approle
```
$ vault auth enable -namespace VisTracks approle
```
Create app-role with unexpired secret-id
```
$ vault write -namespace VisTracks auth/approle/role/jenkins policies="jenkins"
```
Read all info about the app-role
```
$ vault read -namespace VisTracks auth/approle/role/jenkins
```
Read role-id
```
$ vault read -namespace VisTracks auth/approle/role/jenkins/role-id
Key        Value
---        -----
role_id    ROLE_ID
```
Get secret-id

```
$ vault write -namespace VisTracks -f auth/approle/role/jenkins/secret-id
Key                   Value
---                   -----
secret_id             SECRET_ID
secret_id_accessor    ...
Log in as role-id and secret-id
```
$ vault write -namespace VisTracks auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID
```
Log out from vault cli
```
vault token revoke -self
```