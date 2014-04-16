#!/bin/bash

rax_user=$OS_USERNAME
rax_apikey=$OS_API_KEY
tenant_id=$OS_PROJECT_ID

region=syd

api_url="https://$region.loadbalancers.api.rackspacecloud.com/v1.0"


action=$1

function get-token()
{
	auth_url=$OS_AUTH_URL/tokens

	auth_token_info=`curl -s -X POST $auth_url -H 'Accept:application/json' -H 'Content-Type: application/json' -d '{ "auth" : { "RAX-KSKEY:apiKeyCredentials" : { "username": "'$rax_user'" "apiKey": "'$rax_apikey'" } } }'  | jq '.access.token'`

#	export tenant_id=`echo $auth_token_info | jq '.tenant.id' | sed 's/"//g'`
	auth_token=`echo $auth_token_info | jq '.id' | sed 's/"//g'`

	echo $auth_token
}

function update-record()
{
	domain_name=$1
	record_type=$2
	record_name=$3
	record_data=$4

	auth_token=`get-token`

	domain_id=`get-domain-id $domain_name`
	record_id=`get-record-id $domain_name $record_type $record_name`

	if [ -z $record_id ];
	then
		echo "Unable to find record: $record_name ($record_type)"
		exit 1
	fi

	result=`curl -s -X PUT $api_url/$tenant_id/domains/$domain_id/records/$record_id -H 'Accept:application/json' -H 'Content-Type: application/json' -H "X-Auth-Token: $auth_token" -d "{ \"id\" : \"$record_id\",
	\"data\" : \"$record_data\"
	}
	" | jq .status | sed 's/"//g'`
	
	if [ $result != "RUNNING" ];
	then
		echo "Error updating the DNS record. Status: $result"
		exit 1
	fi
}

function lb-list()
{
	auth_token=`get-token`

	if [ -z $auth_token ]
	then
		echo "Unable to authenticate"
		exit 1
	fi

	lbs=`curl -s -X GET $api_url/$tenant_id/loadbalancers/ -H 'Accept:application/json' -H 'Content-Type: application/json'  -H "X-Auth-Token: $auth_token" | jq '.loadBalancers'`

	echo $lbs
}

function get-domain-id()
{
	domain_name=$1

	domains=`domain-list`
	
	domain_id=`echo $domains | jq ".[] | select(.name == \"$domain_name\") | .id"`
	
	if [ -z $domain_id ];
	then
		echo "Unable to find domain: $domain_name"
		exit 1
	fi
	
	echo $domain_id
}

function record-list()
{
	auth_token=`get-token`

	domain_id=`get-domain-id $1`

	records=`curl -s -X GET $api_url/$tenant_id/domains/$domain_id/records -H 'Accept:application/json' -H 'Content-Type: application/json'  -H "X-Auth-Token: $auth_token"`

	echo $records
}

function get-record-id()
{
	domain_name=$1
	record_type=$2
	record_name=$3

	auth_token=`get-token`

	record_list=`record-list $domain_name`

	record_id=` echo $record_list | jq ".records[] | select( .type == \"$record_type\" ) | select( .name == \"$record_name\" ) | .id " | sed 's/"//g'`

	if [ -z $record_id ];
	then
		echo "Unable to find record: $record_name ($record_type)"
		exit 1
	fi

	echo $record_id
}



$1 $2 $3 $4 $5
