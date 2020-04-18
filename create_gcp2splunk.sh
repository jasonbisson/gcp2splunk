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
exit
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
exit
fi 
}

function create_topic () {
gcloud pubsub topics create ${gcp2splunk}
}

function create_sink () {
gcloud logging sinks create ${gcp2splunk} "pubsub.googleapis.com/projects/${project_id}/topics/${gcp2splunk}" --include-children --log-filter="severity>=NOTICE" --organization=${org_id}
gcloud logging sinks update ${gcp2splunk} "pubsub.googleapis.com/projects/${project_id}/topics/${gcp2splunk}" --log-filter="severity>=NOTICE" --organization=${org_id}
sink_account=$(gcloud logging sinks describe ${gcp2splunk} --organization=${org_id} |grep writerIdentity | awk -F: '{print $3}')
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'$sink_account'' --role 'roles/pubsub.publisher' > /dev/null 2>&1
}

function subscribe_2_topic () {
gcloud pubsub subscriptions create ${splunk2gcp} --topic=projects/${project_id}/topics/${gcp2splunk}
}

function create_service_account () {
gcloud iam service-accounts create  ${splunk2gcp} --display-name "${splunk2gcp}"
gcloud iam service-accounts keys create "${splunk2gcp}.key.json" --iam-account "${splunk2gcp}@$project_id.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/viewer' > /dev/null 2>&1
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/pubsub.subscriber' > /dev/null 2>&1
}

function pass2splunk () {
echo ""
echo "${splunk2gcp}.key.json is available to intergrate with Splunk"
echo "Run shred -u ${splunk2gcp}.key.json to destroy the local key after Splunk intergration is complete"
echo ""
echo "If you accidently delete the key run this command to generate a new key"
echo "gcloud iam service-accounts keys create \"${splunk2gcp}.key.json\" --iam-account \"${splunk2gcp}@$project_id.iam.gserviceaccount.com\""
}

check_variables
create_topic
create_sink
subscribe_2_topic
create_service_account
pass2splunk
