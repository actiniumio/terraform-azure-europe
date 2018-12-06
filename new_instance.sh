set -e

## Ensure jq is installed
## https://stedolan.github.io/jq/
which jq > /dev/null


TFOPTS="-var-file credentials.tfvars -var ssh_key_path=/tmp/azure-deployer.pem"

SSH_KEY_PATH="$1"
SSH_KEY_DIR="$(cd $(dirname "$1"); pwd -P)"

AZURE_SSH_KEY_PATH="/tmp/azure-deployer.pfx"

openssl req -x509 \
  -key "$SSH_KEY_DIR/$(basename -- "$SSH_KEY_PATH")" \
  -nodes \
  -days 365 -newkey rsa:2048 \
  -out /tmp/azure-deployer.pem \
  -subj '/CN=www.mydomain.com/O=MyCompany./C=US'

openssl x509 \
  -outform der \
  -in /tmp/azure-deployer.pem \
  -out $AZURE_SSH_KEY_PATH

fingerprint=$(openssl x509 -fingerprint -inform der -in $AZURE_SSH_KEY_PATH | grep "SHA1 Fingerprint")
fingerprint="${fingerprint#*=}"
fingerprint="${fingerprint//:/}"


export AZURE_SSH_KEY_PATH
export AZURE_SSH_KEY_FINGERPRINT=$fingerprint

# Ensure that terraform plugins are available
terraform init

# Refresh remote state
terraform refresh $TFOPTS

# Delete remote instances to start over from scratch (Single dev config, refactor this)
terraform destroy -force $TFOPTS || true

# Generate the planned state (not tracked in SVC, as it can contain sensitive datas such as private keys)
terraform plan $TFOPTS -out allspark_test.plan

terraform apply $TFOPTS .


echo "Connect to the machine on this host"
echo "$(jq '.modules[0].resources."azurerm_public_ip.allspark_test".primary.attributes.ip_address' terraform.tfstate)"
