#!/usr/bin/env sh
set -eu

export ANSIBLE_CONFIG=/workspace/ansible/ansible.cfg

tar -czf /workspace/app/health-app.tar.gz -C /workspace/app/src .

ansible-playbook \
  -i /workspace/ansible/inventory.ini \
  /workspace/ansible/site.yml

touch /tmp/deployment-complete
printf '\nDeployment completed. Keeping the Ansible master available.\n'
tail -f /dev/null
