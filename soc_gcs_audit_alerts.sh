#!/bin/bash
#set -x
export project_id=$(gcloud config get-value project)
export BUCKET=$project_id-expose2internet
export BUCKET_FILE=expose2internet

function create_bucket () {
gsutil mb gs://$BUCKET
}

function create_file () {
touch $BUCKET_FILE
gsutil cp $BUCKET_FILE gs://$BUCKET
}

function update_bucket_allusers () {
gsutil iam ch allUsers:objectViewer gs://$BUCKET
}

function update_bucket_file_allusers () {
gsutil acl ch -u AllUsers:R gs://$BUCKET/$BUCKET_FILE
}

function update_bucket_allAuthenticatedUsers () {
gsutil iam ch allAuthenticatedUsers:objectViewer gs://$BUCKET
}

function update_bucket_file_allAuthenticatedUsers () {
gsutil acl ch -u allAuthenticatedUsers:R gs://$BUCKET/$BUCKET_FILE
}

function review_file_acl () {
gsutil acl get gs://$BUCKET/$BUCKET_FILE
}

function review_bucket_iam () {
gsutil iam get gs://$BUCKET
}

function remove_bucket () {
gsutil rm gs://$BUCKET/$BUCKET_FILE
gsutil rb gs://$BUCKET
}

create_bucket
create_file
update_bucket_allAuthenticatedUsers
update_bucket_file_allAuthenticatedUsers
update_bucket_allusers
update_bucket_file_allusers
#review_file_acl
#review_bucket_iam
remove_bucket
