#!/bin/bash

VAULT_USER_NAME="vault"
VAULT_USER_COMMENT="HashiCorp Vault user"
VAULT_USER_GROUP="vault"
VAULT_USER_HOME="/srv/vault"
VAULT_STORAGE_PATH="/vault/vault01"
VAULT_NODE_ID="vault01"
VAULT_NODE_01="VAULT NODE 01 HTTPS DNS ADDRESS HERE (https://vault01.rickkemery.com:8200)"
VAULT_NODE_02="VAULT NODE 02 HTTPS DNS ADDRESS HERE (https://vault02.rickkemery.com:8200)"
VAULT_NODE_03="VAULT NODE 03 HTTPS DNS ADDRESS HERE (https://vault03.rickkemery.com:8200)"
VAULT_LISTENER_ADDRESS="0.0.0.0:8200"
VAULT_CLUSTER_ADDRESS="0.0.0.0:8201"
VAULT_API_ADDRESS="HTTPS DNS ADDRESS OF API; CAN BE LB VIP DNS (example: https://vip.rickkemery.com:8200)"
VAULT_API_CLUSTER_ADDRESS="HTTPS DNS ADDRESS OF NODE (example: https://vault01.rickkemery.com:8201)"
SYSTEMD_DIR="/etc/systemd/system"

/usr/sbin/groupadd --force --system ${VAULT_USER_GROUP}
/usr/sbin/adduser --system --gid ${VAULT_USER_GROUP} --home ${VAULT_USER_HOME} --no-create-home --comment "${VAULT_USER_COMMENT}" --shell /bin/false ${VAULT_USER_NAME}  >/dev/null
logger "RHEL/CentOS system detected"
logger "Performing updates and installing prerequisites"
yum -y check-update
yum install -q -y wget unzip bind-utils ruby rubygems ntp jq
systemctl start ntpd.service
systemctl enable ntpd.service
logger "Installing Vault"
unzip -o /tmp/vault.zip -d /usr/local/bin
chmod 0755 /usr/local/bin/vault
chown vault:vault /usr/local/bin/vault
mkdir -pm 0755 /etc/vault.d
logger "Moving certs"
mv /tmp/{vault.crt,vault.key,ca.crt} /etc/vault.d/
chmod -R 755 /etc/vault.d
mkdir -pm 0755 /etc/ssl/vault
logger "Configuring Vault"
mkdir -pm 0755 $VAULT_STORAGE_PATH
chown -R vault:vault $VAULT_STORAGE_PATH
chmod -R a+rwx $VAULT_STORAGE_PATH
tee /etc/vault.d/vault.hcl <<EOF
storage "raft" {
  path    = "$VAULT_STORAGE_PATH"
  node_id = "$VAULT_NODE_ID"

  retry_join {
   leader_api_addr = "$VAULT_NODE_01"
   leader_ca_cert_file = "/etc/vault.d/ca.crt"
   leader_client_cert_file = "/etc/vault.d/vault.crt"
   leader_client_key_file = "/etc/vault.d/vault.key"
 }
  retry_join {
   leader_api_addr = "$VAULT_NODE_02"
   leader_ca_cert_file = "/etc/vault.d/ca.crt"
   leader_client_cert_file = "/etc/vault.d/vault.crt"
   leader_client_key_file = "/etc/vault.d/vault.key"
 }
  retry_join {
   leader_api_addr = "$VAULT_NODE_03"
   leader_ca_cert_file = "/etc/vault.d/ca.crt"
   leader_client_cert_file = "/etc/vault.d/vault.crt"
   leader_client_key_file = "/etc/vault.d/vault.key"
 }
}
listener "tcp" {
  address     = "$VAULT_LISTENER_ADDRESS"
  cluster_address     = "$VAULT_CLUSTER_ADDRESS"
  tls_cert_file       = "/etc/vault.d/vault.crt"
  tls_key_file        = "/etc/vault.d/vault.key"
  tls_client_ca_file  = "/etc/vault.d/ca.crt"
  tls_disable = false
}
api_addr = "$VAULT_API_ADDRESS"
cluster_addr = "$VAULT_API_CLUSTER_ADDRESS"
disable_mlock = true
ui=true
EOF

chown -R vault:vault /etc/vault.d /etc/ssl/vault
chmod -R 0644 /etc/vault.d/*

tee -a /etc/environment <<EOF
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
EOF

source /etc/environment

logger "Granting mlock syscall to vault binary"
setcap cap_ipc_lock=+ep /usr/local/bin/vault


read -d '' VAULT_SERVICE <<EOF
[Unit]
Description=Vault
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGTERM
User=vault
Group=vault
[Install]
WantedBy=multi-user.target
EOF


logger "Installing systemd services for RHEL/CentOS"
echo "${VAULT_SERVICE}" | sudo tee $SYSTEMD_DIR/vault.service
chmod 0664 $SYSTEMD_DIR/vault*

systemctl enable vault
systemctl start vault
systemctl status vault
