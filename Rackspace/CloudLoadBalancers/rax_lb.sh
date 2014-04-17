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

function get-lb-id()
{
	lb_name=$1

	lbs=`lb-list`
	
	lb_id=`echo $lbs | jq ".[] | select(.name == \"$lb_name\") | .id"`
	
	if [ -z $lb_id ];
	then
		echo "Unable to find load balancer: $lb_name"
		exit 1
	fi
	
	echo $lb_id
}

function get-lb()
{
	auth_token=`get-token`

	lb_name=$1
	
	lb_id=`get-lb-id $lb_name`
	
	curl -s -X GET $api_url/$tenant_id/loadbalancers/$lb_id -H "X-Auth-Token: $auth_token"
}

function update-lb()
{
	auth_token=`get-token`

	lb_name=$1
	attribute=$2
	value=$3

	lb_id=`get-lb-id $lb_name`

	curl -s -X PUT $api_url/$tenant_id/loadbalancers/$lb_id -H "Content-Type: application/json" -H "X-Auth-Token: $auth_token"  -d "{
    \"loadBalancer\": {
        \"$attribute\": \"$value\"
    }
}"
}

$1 $2 $3 $4 $5
