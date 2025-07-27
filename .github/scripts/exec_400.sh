#!/bin/bash
set -eu

GITHUB_TOKEN=${1:-"github token"}
CONFIG_PATH=${2:-"config file"}


echo -e "\n====== load config file ======"
dir1=$(jq -r '.dir1' "$CONFIG_PATH")
dir2=$(jq -r '.dir2' "$CONFIG_PATH")
dir3=$(jq -r '.dir3' "$CONFIG_PATH")
echo "- dir1: $dir1"
echo "- dir2: $dir2"
echo "- dir3: $dir3"


echo -e "\n====== call gdo 400 workflow ======"
api_url="https://api.github.com/repos/katagiri1999/study/actions/workflows/tmp.yaml/dispatches"
payload=$(cat <<EOF
{
  "ref": "main",
  "inputs": {}
}
EOF
)
echo "PAYLOAD: $payload"
curl -X POST "$api_url" -H "Authorization: Bearer $GITHUB_TOKEN" -d "$payload"


echo -e "\n====== get gdo 400 workflow ======"
sleep 5
api_url="https://api.github.com/repos/katagiri1999/study/actions/workflows/tmp.yaml/runs?branch=main&per_page=1"
res=$(curl "$api_url" -H "Authorization: Bearer $GITHUB_TOKEN")
workflow_runs=$(echo $res | jq -c '.workflow_runs')
mapfile -t workflow_runs < <(echo "$workflow_runs" | jq -c '.[]')
target_run=${workflow_runs[0]}
run_url=$(echo "$target_run" | jq -r '.url')
echo "run_url: $run_url"


echo -e "\n====== wait gdo 400 workflow ======"
api_url=$run_url
status=""

while [ "$status" != "completed" ]; do
  sleep 10
  res=$(curl "$api_url" -H "Authorization: Bearer $GITHUB_TOKEN")
  status=$(echo "$res" | jq -r '.status')
  echo "status: $status"

  if [[ "$status" != "completed" && "$status" != "in_progress" && "$status" != "queued" ]]; then
    echo "invalid response"
    exit 1
  fi
done
jobs_url=$(echo "$res" | jq -r '.jobs_url')
echo "job_url: $jobs_url"


echo -e "\n====== get gdo 400 workflow result ======"
api_url=$jobs_url
res=$(curl "$api_url" -H "Authorization: Bearer $GITHUB_TOKEN")
jobs=$(echo $res | jq -c '.jobs')
mapfile -t jobs < <(echo "$jobs" | jq -c '.[]')
job=${jobs[0]}
check_run_url=$(echo "$job" | jq -r '.check_run_url')
echo "check_run_url: $check_run_url"

api_url=$check_run_url
res=$(curl "$api_url" -H "Authorization: Bearer $GITHUB_TOKEN")
annotations_url=$(echo "$res" | jq -r '.output.annotations_url')
echo "annotations_url: $annotations_url"

api_url=$annotations_url
res=$(curl "$api_url" -H "Authorization: Bearer $GITHUB_TOKEN")

if [[ "$res" == *$dir1* ]]; then
  echo "success"
else
  echo "invalid response"
  exit 1
fi

mapfile -t annotations < <(echo "$res" | jq -c '.[]')
annotation=${annotations[1]}
message=$(echo "$annotation" | jq -r '.message')
docker_image_tag="${message:18}"
echo $docker_image_tag > docker_image_tag
