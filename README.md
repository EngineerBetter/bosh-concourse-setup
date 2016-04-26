BOSH Director & Concourse Bootstrap
===================================

This project achieves the following:

- Preparation of an AWS environment for BOSH & Concourse
- Deployment of a new BOSH Director using bosh-init
- Deployment of a new Concourse cluster, or standalone server

Terraform is used to setup the base network and security infrastructure, including an ELB for Concourse.

Requirements
-----

- Install [terraform](https://www.terraform.io/intro/getting-started/install.html)
- Install [bosh-init](https://bosh.io/docs/install-bosh-init.html)
- Install the [bosh_cli](https://bosh.io/docs/bosh-cli.html)

Ensure you have created a `terraform/terraform.tfvars` file with your variables, or set suitable (environment variables)[https://www.terraform.io/docs/configuration/variables.html]. An example tfvars file can be found in `terraform/terraform.tfvars.example`

Assumptions
-----

You already have:

- A Route53 Zone in AWS.
- An EC2 SSH keypair
- An SSL certificate in AWS for your Concourse ELB

Usage
-----

Ensure terraform is in your path, then apply the configuration to prepare the IaaS for BOSH and Concourse:

```
cd terraform/
terraform apply
```
Set the following environment variables:

```
$AWS_ACCESS_KEY_ID
$AWS_SECRET_ACCESS_KEY
$BOSH_PASSWORD
$AWS_KEYPAIR_KEY_NAME
$PRIVATE_KEY_PATH
```

Then create the `bosh-director.yml` manifest:
```
./bin/make_manifest_bosh-init.sh
```

You are ready to deploy the BOSH Director
```
bosh-init deploy bosh-director.yml
```

Go and make a cup of tea.

Once the director is deployed, target it and apply your cloud-config for AWS
```
bosh target <your EIP address>
bosh update cloud-config aws-cloud.yml
```

Set the Concourse URL and password in these environment variables:
```
ATC_URL
fly_target
```

Create a concourse manifest for a single server deployment:
```
./bin/make_manifest_concourse.sh
```
Or, create a concourse manifest for small cluster:
```
./bin/make_manifest_concourse-cluster.sh
```

Upload the necessary stemcell & releases, then deploy concourse:
```
bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent
bosh upload release https://bosh.io/d/github.com/concourse/concourse
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release
bosh deployment concourse.yml
bosh deploy
```
