#!/bin/bash
#set -x

if [ $# -ne 1 ]; then
    echo $0: usage: Requires argument of Organizational name e.g.   your_dns_domain.com
    exit 1
fi

export org_name=$1
export project_id=$(gcloud config get-value project)
export org_id=$(gcloud organizations list --format=[no-heading] | grep ^${org_name} | awk '{print $2}')
export gcp2splunk=gcp2splunk
export splunk2gcp=splunk2gcp

function check_variables () {
if [  -z "$project_id" ]; then 
printf "ERROR: GCP PROJECT_ID is not set.\n\n" 
printf "To view the current PROJECT_ID config: gcloud config list project \n\n"
printf "To view available projects: gcloud projects list \n\n" 
printf "To update project config: gcloud config set project PROJECT_ID \n\n" 
exit 1
fi

gcloud projects describe $project_id > /dev/null 2>&1
if [ $? -eq 1 ]; then
printf "ERROR:Project ID  $project_id is not valid or you don't have permission\n\n"
printf "To view the current PROJECT_ID config: gcloud config list project \n\n"
printf "To view available projects: gcloud projects list \n\n" 
printf "To update project config: gcloud config set project PROJECT_ID \n\n" 
exit 1
fi

if [  -z "$org_id" ]; then
printf "ERROR: GCP organization id is not set.\n\n" 
printf "To check if you have Organizational rights: gcloud organizations list\n\n"
printf "Or $org_name has a typo which would impact the lookup for the Organizational ID\n\n"
exit 1
fi 
}

function delete_topic () {
gcloud pubsub topics delete ${gcp2splunk}
}

function delete_sink () {
sink_account=$(gcloud logging sinks describe ${gcp2splunk} --organization=${org_id} |grep writerIdentity | awk -F: '{print $3}')
gcloud projects remove-iam-policy-binding $project_id --member 'serviceAccount:'${sink_account}'' --role 'roles/pubsub.publisher' > /dev/null 2>&1
gcloud logging sinks delete --quiet ${gcp2splunk} --organization=${org_id}
}

function delete_subscribe () {
gcloud pubsub subscriptions delete ${splunk2gcp} 
}

function delete_service_account () {
gcloud projects remove-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/viewer' > /dev/null 2>&1
gcloud projects remove-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/pubsub.subscriber' > /dev/null 2>&1
gcloud iam service-accounts delete --quiet ${splunk2gcp}@$project_id.iam.gserviceaccount.com
}

check_variables
delete_service_account
delete_subscribe
delete_sink
delete_topic
