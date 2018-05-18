Simple bash script executing gcloud commands to stream log events from Google Cloud Platform (GCP) to be consumed by a Splunk instance. 

Requirements:
User must have permission at the Organization/Folder Level. 
User executes the script from the Google Cloud Shell to ensure API scopes are enabled and environmental variables of the 

What this script will automated on the GCP side:
1) Creates pub/sub topic to stream logs events
2) Creates the aggregate sink to write to pub/sub topic at the organizational level.
3) Grant IAM pubsub.publisher to the aggregate sink service account for the pub/sub topic.
4) Creates a pub/sub subscription for Splunk to subscribe to events.
5) Creates a service account and JSON key that will be used by the Splunk instance to pull from the subscription.
    Project level — role/project.viewer 
    Subscription level — role/pubsub.subscriber

What you need to do on the Splunk side:
http://docs.splunk.com/Documentation/AddOns/released/GoogleCloud/installation

Security clean up:
After the connection to Splunk validated shred the JSON key that was downloaded to the Google Cloud Shell.
shred -u splunk2gcp.key.json 
