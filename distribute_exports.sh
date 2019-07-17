
#!/bin/bash
set -x

if [ $# -ne 1 ]; then
    echo $0: usage: Requires argument of Organizational name e.g.   your_dns_domain.com
    exit 1
fi

export org_name=$1
export project_id=$(gcloud config get-value project)
export org_id=$(gcloud organizations list --format=[no-heading] | grep ${org_name} | awk '{print $2}')
export splunk2gcp=splunk2gcp

function audit_export () {
export gcp2splunk=audit.${org_name}
export logname="/logs/cloudaudit.googleapis.com%2Factivity"
gcloud pubsub topics create ${gcp2splunk}
gcloud logging sinks create ${gcp2splunk} "pubsub.googleapis.com/projects/${project_id}/topics/${gcp2splunk}" --include-children --log-filter="log_name:"${logname}" AND severity>=NOTICE" --organization=${org_id}
sink_account=$(gcloud logging sinks describe ${gcp2splunk} --organization=${org_id} |grep writerIdentity | awk -F: '{print $3}')
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'$sink_account'' --role 'roles/pubsub.publisher' > /dev/null 2>&1
gcloud pubsub subscriptions create ${gcp2splunk} --topic=projects/${project_id}/topics/${gcp2splunk}
}

function data_export () {
export gcp2splunk=data.${org_name}
export logname="/logs/cloudaudit.googleapis.com%2Fdata_access"
gcloud pubsub topics create ${gcp2splunk}
gcloud logging sinks create ${gcp2splunk} "pubsub.googleapis.com/projects/${project_id}/topics/${gcp2splunk}" --include-children --log-filter="log_name:"${logname}" AND severity>=NOTICE" --organization=${org_id}
sink_account=$(gcloud logging sinks describe ${gcp2splunk} --organization=${org_id} |grep writerIdentity | awk -F: '{print $3}')
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'$sink_account'' --role 'roles/pubsub.publisher' > /dev/null 2>&1
gcloud pubsub subscriptions create ${gcp2splunk} --topic=projects/${project_id}/topics/${gcp2splunk}
}

function system_export () {
export gcp2splunk=system.${org_name}
export logname="/logs/cloudaudit.googleapis.com%2Fsystem_event"
gcloud pubsub topics create ${gcp2splunk}
gcloud logging sinks create ${gcp2splunk} "pubsub.googleapis.com/projects/${project_id}/topics/${gcp2splunk}" --include-children --log-filter="log_name:"${logname}" AND severity>=NOTICE" --organization=${org_id}
sink_account=$(gcloud logging sinks describe ${gcp2splunk} --organization=${org_id} |grep writerIdentity | awk -F: '{print $3}')
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'$sink_account'' --role 'roles/pubsub.publisher' > /dev/null 2>&1
gcloud pubsub subscriptions create ${gcp2splunk} --topic=projects/${project_id}/topics/${gcp2splunk}
}

function create_service_account () {
gcloud iam service-accounts create  ${splunk2gcp} --display-name "${splunk2gcp}"
gcloud iam service-accounts keys create "${splunk2gcp}.key.json" --iam-account "${splunk2gcp}@$project_id.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/viewer' > /dev/null 2>&1
gcloud projects add-iam-policy-binding $project_id --member 'serviceAccount:'${splunk2gcp}'@'${project_id}'.iam.gserviceaccount.com' --role 'roles/pubsub.subscriber' > /dev/null 2>&1
}

audit_export
data_export
system_export
create_service_account
