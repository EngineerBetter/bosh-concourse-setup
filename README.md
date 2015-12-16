BOSH Director Example
==========================

Deployment of a BOSH Director using bosh-init, from scratch on AWS.

Terraform is used to setup the base network and security infrastructure.

Usage
-----

- Install terraform
- Install bosh-init

Ensure you have created a terraform.tfvars file with the vars you need, or set suitable environment variables.

Ensure terraform is in your path, then run:

```
cd terraform/
terraform apply
```

Then create the `bosh-director.yml` manifest:

```
./bin/make_manifest.sh
```

You are ready to deploy the BOSH Director
```
bosh-init deploy bosh-director.yml
```
