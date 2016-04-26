BOSH Director & Concourse Bootstrap
===================================

This project achieves the following:

1) Preparation of an AWS environment for BOSH & Concourse
2) Deployment of a new BOSH Director using bosh-init
2) Deployment of a new Concourse cluster

Terraform is used to setup the base network and security infrastructure.

Usage
-----

- Install terraform
- Install bosh-init

Ensure you have created a terraform/terraform.tfvars file with the vars you need, or set suitable environment variables.

Ensure terraform is in your path, then apply the configuration to prepare the IaaS for BOSH and Concourse:

```
cd terraform/
terraform apply
```

Then create the `bosh-director.yml` manifest:
```
./bin/make_manifest_bosh-init.sh
```

You are ready to deploy the BOSH Director
```
bosh-init deploy bosh-director.yml
```

Target your new Directors and apply your cloud-config for AWS
```
bosh target <your EIP address>
bosh update cloud-config aws-cloud.yml
```

Create the concourse manifest:
```
./bin/make_manifest_concourse.sh
```

Upload a stemcell & releases, then deploy concourse:
```
bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent
bosh upload release https://bosh.io/d/github.com/concourse/concourse
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release
bosh deployment concourse.yml
bosh deploy
```
