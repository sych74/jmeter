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
