#!/bin/bash
#
#  Please set the following environment variables:
#  $AWS_ACCESS_KEY_ID
#  $AWS_SECRET_ACCESS_KEY
#  $BOSH_PASSWORD
#  $AWS_KEYPAIR_KEY_NAME
#  $PRIVATE_KEY_PATH

function getvars() {
  cd terraform/
  EIP=$(terraform output eip)
  SUBNET=$(terraform output subnet_id)
  SECURITY_GROUP=$(terraform output security_group_id)
  cd ../
}

getvars

echo "Subnet = $SUBNET"
echo "Security Group = $SECURITY_GROUP"
echo "EIP = $EIP"

cat >bosh-director.yml <<YAML
---
name: bosh

releases:
- name: bosh
  url: https://bosh.io/d/github.com/cloudfoundry/bosh?v=255.10
  sha1: 013e75a62b0511ec714e89444964c63cbc289b09
- name: bosh-aws-cpi
  url: https://bosh.io/d/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?v=51
  sha1: 7856e0d1db7d679786fedd3dcb419b802da0434b

resource_pools:
- name: vms
  network: private
  stemcell:
    url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3215.4
    sha1: 02e0491d89cc94080839d502949eb09f33a5bf3d
  cloud_properties:
    instance_type: m3.large
    ephemeral_disk: {size: 25_000, type: gp2}
    availability_zone: eu-west-1a # <--- Replace with Availability Zone

disk_pools:
- name: disks
  disk_size: 20_000
  cloud_properties: {type: gp2}

networks:
- name: private
  type: manual
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    dns: [10.0.0.2]
    cloud_properties: {subnet: $SUBNET} # <--- Replace with Subnet ID
- name: public
  type: vip

jobs:
- name: bosh
  instances: 1

  templates:
  - {name: nats, release: bosh}
  - {name: redis, release: bosh}
  - {name: postgres, release: bosh}
  - {name: blobstore, release: bosh}
  - {name: director, release: bosh}
  - {name: health_monitor, release: bosh}
  - {name: registry, release: bosh}
  - {name: aws_cpi, release: bosh-aws-cpi}

  resource_pool: vms
  persistent_disk_pool: disks

  networks:
  - name: private
    static_ips: [10.0.0.6]
    default: [dns, gateway]
  - name: public
    static_ips: [$EIP] # <--- Replace with Elastic IP

  properties:
    nats:
      address: 127.0.0.1
      user: nats
      password: $BOSH_PASSWORD

    redis:
      listen_address: 127.0.0.1
      address: 127.0.0.1
      password: $BOSH_PASSWORD

    postgres: &db
      listen_address: 127.0.0.1
      host: 127.0.0.1
      user: postgres
      password: $BOSH_PASSWORD
      database: bosh
      adapter: postgres

    registry:
      address: 10.0.0.6
      host: 10.0.0.6
      db: *db
      http: {user: admin, password: $BOSH_PASSWORD, port: 25777}
      username: admin
      password: $BOSH_PASSWORD
      port: 25777

    blobstore:
      address: 10.0.0.6
      port: 25250
      provider: dav
      director: {user: director, password: $BOSH_PASSWORD}
      agent: {user: agent, password: $BOSH_PASSWORD}

    director:
      address: 127.0.0.1
      name: my-bosh
      db: *db
      cpi_job: aws_cpi
      max_threads: 10
      user_management:
        provider: local
        local:
          users:
          - {name: admin, password: $BOSH_PASSWORD}
          - {name: hm, password: $BOSH_PASSWORD}

    hm:
      director_account: {user: hm, password: $BOSH_PASSWORD}
      resurrector_enabled: true

    aws: &aws
      access_key_id: $AWS_ACCESS_KEY_ID
      secret_access_key: $AWS_SECRET_ACCESS_KEY
      default_key_name: $AWS_KEYPAIR_KEY_NAME
      default_security_groups: [$SECURITY_GROUP]
      region: eu-west-1

    agent: {mbus: "nats://nats:$BOSH_PASSWORD@10.0.0.6:4222"}

    ntp: &ntp [0.pool.ntp.org, 1.pool.ntp.org]

cloud_provider:
  template: {name: aws_cpi, release: bosh-aws-cpi}

  ssh_tunnel:
    host: $EIP # <--- Replace with your Elastic IP address
    port: 22
    user: vcap
    private_key: $PRIVATE_KEY_PATH # Path relative to this manifest file

  mbus: "https://mbus:$BOSH_PASSWORD@$EIP:6868" # <--- Replace with Elastic IP

  properties:
    aws: *aws
    agent: {mbus: "https://mbus:$BOSH_PASSWORD@0.0.0.0:6868"}
    blobstore: {provider: local, path: /var/vcap/micro_bosh/data/cache}
    ntp: *ntp
YAML
