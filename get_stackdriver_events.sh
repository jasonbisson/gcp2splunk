#!/bin/bash
#set -x
[[ "$#" -ne 4 ]] && { echo "Usage : `basename "$0"` --dns-domain <your_dns_domain> --freshness <Number_of_days>"; exit 1; }
[[ "$1" = "--dns-domain" ]] &&  export org_name=$2
[[ "$3" = "--freshness" ]] &&  export FRESHNESS=$4

export org_id=$(gcloud organizations list --format=[no-heading] | grep ${org_name} | awk '{print $2}')

function stackdriver_org () {
gcloud logging read "logName:cloudaudit.googleapis.com%2Factivity" --organization=${org_id} --freshness=${FRESHNESS}d --format json
}

function stackdriver_folder () {
export folder_list=$(gcloud alpha resource-manager folders list --format=[no-heading] --organization=$org_id |awk '{print $3}')
for x in "$folder_list"
do
gcloud logging read "logName:cloudaudit.googleapis.com%2Factivity" --folder=${x} --freshness=${FRESHNESS}d --format json
done
}

function stackdriver_project () {
for x in $(gcloud logging logs list |grep cloudaudit)
do
gcloud logging read "logName=${x}" --freshness=${FRESHNESS}d --format json
done
}

stackdriver_org
stackdriver_folder
stackdriver_project
