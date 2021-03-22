#! /usr/bin/env bash
# Add vagrant user to demo with virtualbox

do_vagrant() {

  echo ">>> Setting up vagrant"
  set -e
  set -x

  date | tee /etc/vagrant_box_build_time

  /usr/sbin/groupadd vagrant
  /usr/sbin/useradd vagrant -g vagrant -G wheel
  echo 'vagrant' | passwd --stdin vagrant
  cat <<EOF > /etc/sudoers.d/vagrant
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 440 /etc/sudoers.d/vagrant

  mkdir -p ~vagrant/.ssh
  curl -fsSLo ~vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
  chmod 700 ~vagrant/.ssh/
  chmod 600 ~vagrant/.ssh/authorized_keys
  chown -R vagrant.vagrant ~vagrant/.ssh
}

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
  do_vagrant
fi
