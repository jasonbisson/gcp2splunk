#!/bin/bash
#set -x

if [ $# -ne 1 ]; then
    echo $0: usage: Requires argument of Organizational name e.g.   your_dns_domain.com
    exit 1
fi

export org_name=$1
export project_id=$(gcloud config get-value project)
export org_id=$(gcloud organizations list --format=[no-heading] | grep ${org_name} | awk '{print $2}')
export gcp2splunk=gcp2splunk
export splunk2gcp=splunk2gcp

function delete_topic () {
gcloud beta pubsub topics delete ${gcp2splunk}
}

function delete_sink () {
sink_account=$(gcloud logging sinks describe ${gcp2splunk} --organization=${org_id} |grep writerIdentity | awk -F: '{print $3}')
gcloud projects remove-iam-policy-binding $project_id --member 'serviceAccount:'${sink_account}'' --role 'roles/pubsub.publisher' > /dev/null 2>&1
gcloud logging sinks delete --quiet ${gcp2splunk} --organization=${org_id}
}

function delete_subscribe () {
gcloud alpha pubsub subscriptions delete ${splunk2gcp} 
}

function delete_service_account () {
gcloud projects remove-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/viewer' > /dev/null 2>&1
gcloud projects remove-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/pubsub.subscriber' > /dev/null 2>&1
gcloud iam service-accounts delete --quiet ${splunk2gcp}@$project_id.iam.gserviceaccount.com
}

delete_service_account
delete_subscribe
delete_sink
delete_topic
