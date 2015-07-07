#!/bin/bash
WAITING=true
COUNT=0

echo "Looking for $QUAY_REPOSITORY:$QUAY_TAG"

while $WAITING; do
  sleep 5
  STATUS=`curl --silent -L -H "Authorization: Bearer $QUAY_TOKEN" https://quay.io/api/v1/repository/$QUAY_REPOSITORY/build | jq -r ".builds[] | if (.tags | contains([\"$QUAY_TAG\"])) then .phase else \"not-found\" end"`
  echo "Got Status: $STATUS"
  if [ "$STATUS" == 'complete' ]; then
    WAITING=false
  fi
  COUNT=$((COUNT+1))
  if [ $COUNT -gt 120 ]; then
    echo "Wait time exceeded, giving up."
    exit 1
  fi
done

aws deploy create-deployment --application-name ${DEPLOY_APPLICATION_NAME} --region ${DEPLOY_REGION} --deployment-group ${DEPLOYMENT_GROUP} --revision "{\"revisionType\":\"S3\", \"s3Location\": {\"bucket\": \"${DEPLOY_BUCKET}\", \"key\": \"${DEPLOY_KEY}\", \"bundleType\": \"zip\"}}"
