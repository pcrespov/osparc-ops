#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath ${this_script_dir}/../)
scripts_dir=$(realpath ${repo_basedir}/scripts)

# VCS info on current repo
current_git_url=$(git config --get remote.origin.url)
current_git_branch=$(git branch | grep \* | cut -d ' ' -f2)


# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
source ${repo_basedir}/repo.config
source ${repo_basedir}/services/portainer/.env

# create certificates
make create-certificates
# install certificates (needs to be sudo)
sudo make install-root-certificates
# restart docker service (needs to be sudo)
sudo service docker restart

# start portainer
echo
echo starting portainer
pushd ${repo_basedir}/services/portainer
make up
popd

# start traefik with self-signed certificates
echo
echo starting traefik
pushd ${repo_basedir}/services/traefik
cp ${repo_basedir}/certificates/rootca.crt secrets/rootca.crt
cp ${repo_basedir}/certificates/domain.crt secrets/domain.crt
cp ${repo_basedir}/certificates/domain.key secrets/domain.key
make up
popd

echo
echo starting minio
pushd ${repo_basedir}/services/minio
make up
popd

echo
echo starting portus/registry
pushd ${repo_basedir}/services/portus
cp ${repo_basedir}/certificates/rootca.crt secrets/rootca.crt
cp ${repo_basedir}/certificates/domain.crt secrets/portus.crt
cp ${repo_basedir}/certificates/domain.key secrets/portus.key
make up
popd

echo
echo starting monitoring
pushd ${repo_basedir}/services/monitoring
make up
popd

echo
echo starting graylog
pushd ${repo_basedir}/services/graylog
make up
popd

echo
echo starting deployment-agent/simcore
pushd ${repo_basedir}/services/deployment-agent
make build up
popd