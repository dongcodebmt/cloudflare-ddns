#!/bin/bash

# Cloudflare DDNS
# A bash script to update Cloudflare DNS

dir=`dirname $(readlink -f "$0")`
# Load config from config.conf
. $dir/config.conf

#Regex ip from cloudflare cdn-cgi/trace
ip_regex="((([0-9]{1,3}\.){3}[0-9]{1,3})|(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4}))"

a_record_update () {
	#Get ipv4
	ipv4_request=$(curl -s -X GET https://1.1.1.1/cdn-cgi/trace)
	ipv4=$(echo $ipv4_request | sed -E "s/.*ip=($ip_regex).*/\1/")

	if [ "$ipv4" == "" ];then
		return
	fi
	dns_record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records?type=A&name=$cloudflare_record_name" \
		-H "Authorization: Bearer $cloudflare_api_token" \
		-H "Content-Type: application/json")
	if [[ $dns_record == *"\"count\":0"* ]]; then
		echo "$(get_date): Please create A record with IP ${ipv4} for ${cloudflare_record_name}!"
		return
	fi
	old_ipv4=$(echo $dns_record | sed -E "s/.*\"content\":\"($ip_regex)\".*/\1/")
	if [ $ipv4 == $old_ipv4 ]; then
		echo "$(get_date): A record has not change!"
		return
	fi
	a_record_id=$(echo "$dns_record" | sed -E 's/.*"id":"(\w+)".*/\1/')
	dns_update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records/$a_record_id" \
		-H "Authorization: Bearer $cloudflare_api_token" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"A\",\"name\":\"$cloudflare_record_name\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":false}")
	if [[ $dns_update == *"\"success\":false"* ]]; then
		echo "$(get_date): Updating A record to ${ipv4} failed!"
		return
	fi
	echo "$(get_date): Updating A record to ${ipv4} was successful!"
}

aaaa_record_update () {
	ipv6_request=$(curl -s -X GET https://[2606:4700:4700::1111]/cdn-cgi/trace)
	ipv6=$(echo $ipv6_request | sed -E "s/.*ip=($ip_regex).*/\1/")

	if [ "$ipv6" == "" ];then
		return
	fi
	dns_record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records?type=AAAA&name=$cloudflare_record_name" \
		-H "Authorization: Bearer $cloudflare_api_token" \
		-H "Content-Type: application/json")
	if [[ $dns_record == *"\"count\":0"* ]]; then
		echo "$(get_date): Please create AAAA record with IP ${ipv6} for ${cloudflare_record_name}!"
		return
	fi
	old_ipv6=$(echo $dns_record | sed -E "s/.*\"content\":\"($ip_regex)\".*/\1/")
	if [ $ipv6 == $old_ipv6 ]; then
		echo "$(get_date): AAAA record has not change!"
		return
	fi
	aaaa_record_id=$(echo "$dns_record" | sed -E 's/.*"id":"(\w+)".*/\1/')
	dns_update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records/$aaaa_record_id" \
		-H "Authorization: Bearer $cloudflare_api_token" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"AAAA\",\"name\":\"$cloudflare_record_name\",\"content\":\"$ipv6\",\"ttl\":1,\"proxied\":false}")
	if [[ $dns_update == *"\"success\":false"* ]]; then
		echo "$(get_date): Updating AAAA record to ${ipv6} failed!"
		return
	fi
	echo "$(get_date): Updating AAAA record to ${ipv6} was successful!"
}

get_date() {
	echo $(date '+%Y-%m-%dT%T.%3N')
}

main () {
	if [ "$event_log" == true ] ; then
		filename=$(date '+%Y-%m-%d')
		if [ ! -e $dir/logs ]; then
    			mkdir $dir/logs
		fi
		if [ "$cloudflare_a_record" == true ] ; then
        		a_record_update >> $dir/logs/$filename.log
		fi
		if [ "$cloudflare_aaaa_record" == true ] ; then
        		aaaa_record_update >> $dir/logs/$filename.log
		fi
	else
		if [ "$cloudflare_a_record" == true ] ; then
			a_record_update
		fi
		if [ "$cloudflare_aaaa_record" == true ] ; then
			aaaa_record_update
		fi
	fi
}

main