#!/bin/bash

while getopts u:r:t:d: option
do
 case "${option}"
 in
 u) USERS_COUNT=${OPTARG};;
 r) RAMP_TIME=${OPTARG};;
 d) URL=${OPTARG};;
 *) echo "ERROR";;
 esac
done

CONFIG="/root/TEST_PLAN.jmx"
TEMPLATE="/root/TEST_PLAN-MAGENTO.template"


cp $TEMPLATE $CONFIG

# Set host
if [ -n "$URL" ]
then
    DOMAIN=$(basename "$URL")
    xmlstarlet edit -L -u "/jmeterTestPlan/hashTree/TestPlan/elementProp[@testname='User Defined Variables']/collectionProp/elementProp[@name='host']/stringProp[@name='Argument.value']" -v "$DOMAIN" $CONFIG
fi

# Set Rumpup time
if [ -n "$RAMP_TIME" ]
then
    RAMP_TIME=$(( $RAMP_TIME*60 ))
    [ "x$RAMP_TIME" != "x0" ] || RAMP_TIME=1
    xmlstarlet edit -L -u "/jmeterTestPlan/hashTree/TestPlan/elementProp[@testname='User Defined Variables']/collectionProp/elementProp[@name='ramp_period']/stringProp[@name='Argument.value']" -v "$RAMP_TIME" $CONFIG
fi

# Set protocol
PROTOCOL=$(echo $URL| sed -e 's,:.*,,g')
if [[ -n "$PROTOCOL" && "x${PROTOCOL^^}" == "xHTTPS" ]]
then
    xmlstarlet edit -L -u "/jmeterTestPlan/hashTree/TestPlan/elementProp[@testname='User Defined Variables']/collectionProp/elementProp[@name='request_protocol']/stringProp[@name='Argument.value']" -v "https" $CONFIG
elif [[ -n "$PROTOCOL" && "x${PROTOCOL^^}" == "xHTTP" ]]
then
    xmlstarlet edit -L -u "/jmeterTestPlan/hashTree/TestPlan/elementProp[@testname='User Defined Variables']/collectionProp/elementProp[@name='request_protocol']/stringProp[@name='Argument.value']" -v "http" $CONFIG
fi

# Set users
WORKERS_COUNT=$(grep -v "^$" /root/workers_*|wc -l)
USERS_PER_NODE=$(( $USERS_COUNT/$WORKERS_COUNT ))
[ $USERS_PER_NODE -gt 1000 ] && { echo "Not enough workers nodes. Maximum users count per worker is 135. For running test with $USERS_COUNT you should have $(( $USERS_COUNT/135 )) nodes"; exit 1; }
USERS_COUNT=$USERS_PER_NODE
[ "x$USERS_COUNT" != "x0" ] || USERS_COUNT=1

frontendPoolUsers=$(( $USERS_COUNT*90/100 ))
[ "x$frontendPoolUsers" != "x0" ] || frontendPoolUsers=1
[ ! -n "$frontendPoolUsers" ] || xmlstarlet edit -L -u "/jmeterTestPlan/hashTree/TestPlan/elementProp[@testname='User Defined Variables']/collectionProp/elementProp[@name='frontendPoolUsers']/stringProp[@name='Argument.value']" -v "$frontendPoolUsers"  $CONFIG

adminPoolUsers=$(( $USERS_COUNT*10/100 ))
[ "x$adminPoolUsers" != "x0" ] || adminPoolUsers=1
[ ! -n "$adminPoolUsers" ] || xmlstarlet edit -L -u "/jmeterTestPlan/hashTree/TestPlan/elementProp[@testname='User Defined Variables']/collectionProp/elementProp[@name='adminPoolUsers']/stringProp[@name='Argument.value']" -v "$adminPoolUsers"  $CONFIG


