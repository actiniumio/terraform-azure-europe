# Setup

- Create a `credentials.tfvars` file with your azure credentials like so :

```
client_id = "your.email@azure.cloud.account"
client_secret = "password"
```

You can also use the [Azure command line tool](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) to authenticate with `az login`.

# Provisioning

```bash
./new_instance.sh /path/to/the/private.key
```
