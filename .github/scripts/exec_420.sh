#!/bin/bash
set -eu

GITHUB_TOKEN=${1:-"github token"}
CONFIG_PATH=${2:-"config file"}
DOCKER_IMAGE_TAG=${3:-"docker image tag"}


echo -e "\n====== load config file ======"
dir1=$(jq -r '.dir1' "$CONFIG_PATH")
dir2=$(jq -r '.dir2' "$CONFIG_PATH")
dir3=$(jq -r '.dir3' "$CONFIG_PATH")
test_list=$(jq -c '.test_list' "$CONFIG_PATH")
echo "- dir1: $dir1"
echo "- dir2: $dir2"
echo "- dir3: $dir3"
echo "- test_list: $test_list"


echo -e "\n====== call gdo 420 workflow ======"
echo "docker image tag: $DOCKER_IMAGE_TAG"
mapfile -t rows < <(echo "$test_list" | jq -c '.[]')
for i in "${!rows[@]}"; do
  row="${rows[$i]}"

  env_name=$(echo "$row" | jq -r '.env_name')
  echo "- test: $i"
  echo "  - env_name: $env_name"
done
