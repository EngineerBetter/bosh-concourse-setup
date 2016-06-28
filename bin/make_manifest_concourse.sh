#!/bin/bash
#
#  Please set the following environment variables:
#  $CONCOURSE_PASSWORD
#  $CONCOURSE_URL

DIRECTOR_UUID=`bosh status --uuid`

echo "director_uuid = $DIRECTOR_UUID"
echo "concourse url = $CONCOURSE_URL"

cat >concourse.yml <<YAML
---
name: concourse

director_uuid: $DIRECTOR_UUID

releases:
- name: concourse
  version: latest
- name: garden-runc
  version: latest

stemcells:
- alias: trusty
  os: ubuntu-trusty
  version: latest

instance_groups:
- name: concourse
  instances: 1
  vm_type: concourse_standalone
  stemcell: trusty
  azs: [z1]
  networks: [{name: ops_services}]
  jobs:
  - name: atc
    release: concourse
    properties:
      # replace with your CI's externally reachable URL e.g https://blah
      external_url: $CONCOURSE_URL

      # replace with username/password, or configure GitHub auth
      basic_auth_username: admin
      basic_auth_password: $CONCOURSE_PASSWORD

      postgresql_database: &atc_db atc

      publicly_viewable: true # anyone can view the main pipeline page

  - name: tsa
    release: concourse
    properties: {}

  - name: postgresql
    release: concourse
    properties:
      databases:
      - name: *atc_db
        # make up a role and password
        role: dbrole
        password: $CONCOURSE_PASSWORD

  - name: groundcrew
    release: concourse
    properties: {}

  - name: baggageclaim
    release: concourse
    properties: {}

  - name: garden
    release: garden-runc
    properties:
      garden:
        listen_network: tcp
        listen_address: 0.0.0.0:7777

update:
  canaries: 1
  max_in_flight: 1
  serial: false
  canary_watch_time: 1000-60000
  update_watch_time: 1000-60000
