#!/bin/bash
#set -x
ALERTNAME=$1
PROMETHEUS_ENDPOINT=192.168.1.58:8081/api/v1/alerts

severity_2_nagios()
{
case $1 in
 "critical")
     SEVERITY_CODE=2
 ;;
 "warning")
     SEVERITY_CODE=1
 ;;
 *)
     SEVERITY_CODE=3
 ;;
esac
}

CURL_STATUS=`curl --write-out %{http_code} --output /dev/null --silent -k $PROMETHEUS_ENDPOINT`
if [[ "$CURL_STATUS" -ne 200 ]];then
   echo ERROR - Connectivity to Openshift Prometheus lost.
   exit 2
fi

CHECK="`curl -k $PROMETHEUS_ENDPOINT | jq -r '.data.alerts[].labels.alertname' | grep -i $ALERTNAME`"

if [ "$CHECK" == "$ALERTNAME" ];then
   if [ "$ALERTNAME" == "Watchdog" ];then
          echo Watchdog alert found. Prometheus is OK
          exit 0
  else
	  SEVERITY=`curl -k $PROMETHEUS_ENDPOINT | jq -r --arg ALERTNAME "$ALERTNAME" '.data.alerts[]|select(.labels.alertname as $alertname|.labels.alertname|contains($ALERTNAME))'|jq -r '.labels.severity'`
          severity_2_nagios $SEVERITY
          echo $SEVERITY - $1
          exit $SEVERITY_CODE
   fi
 else
   echo OK - $1 Status OK
   exit 0
fi
