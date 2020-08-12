# bash-vault-enterprise-raft-install-script
bash-vault-enterprise-raft-install-script

## Fill out variables:
* `VAULT_USER_NAME="vault"
* VAULT_USER_COMMENT="HashiCorp Vault user"
* VAULT_USER_GROUP="vault"
* VAULT_USER_HOME="/srv/vault"
* VAULT_STORAGE_PATH="/vault/vault01"
* VAULT_NODE_ID="vault01"
* VAULT_NODE_01="VAULT NODE 01 HTTPS DNS ADDRESS HERE (https://vault01.rickkemery.com:8200)"
* VAULT_NODE_02="VAULT NODE 02 HTTPS DNS ADDRESS HERE (https://vault02.rickkemery.com:8200)"
* VAULT_NODE_03="VAULT NODE 03 HTTPS DNS ADDRESS HERE (https://vault03.rickkemery.com:8200)"
* VAULT_LISTENER_ADDRESS="0.0.0.0:8200"
* VAULT_CLUSTER_ADDRESS="0.0.0.0:8201"
* VAULT_API_ADDRESS="HTTPS DNS ADDRESS OF API; CAN BE LB VIP DNS (example: https://vip.rickkemery.com:8200)"
* VAULT_API_CLUSTER_ADDRESS="HTTPS DNS ADDRESS OF NODE (example: https://vault01.rickkemery.com:8201)"
* SYSTEMD_DIR="/etc/systemd/system`

## Acquire certificates:
> `Place vault.crt, vault.key, and ca.crt into /tmp folder.`

## Acquire vault binary:
> `Place vault.zip in /tmp folder.`

## Run script:
* `chmod +x install-vault.sh
* sudo ./install-vault.sh`
