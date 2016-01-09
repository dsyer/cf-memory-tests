#!/bin/bash

echo $*

if [ "${1}" == "id" ]; then
    echo Skipping header
    exit 0
fi

if [ "${1#\#*}" != "${1}" ]; then
    echo Skipping comment
    exit 0
fi

id=$1; shift
app=$1; shift
type=$1; shift
limit=$1; shift
opts=-Xmx${1}M; shift
opts="$opts -Xms${1}M"; shift
opts="$opts -Xss${1}K"; shift
opts="$opts -XX:MaxMetaspaceSize=${1}M"; shift
opts="$opts -XX:MetaspaceSize=${1}M"; shift
opts="$opts -XX:CompressedClassSpaceSize=${1}M"; shift
opts="$opts -XX:ReservedCodeCacheSize=${1}M"; shift
opts="$opts $*"

cf delete ${app}-sample -f -r
DIR=build/$id/$type/$limit

mkdir -p $DIR
sed -e "s/%{app}/${app}/" -e "s/%{memory}/${limit}/" -e "s/%{opts}/${opts}/" manifest.yml.tmpl > $DIR/manifest.yml

cf push ${app}-sample -f $DIR/manifest.yml -p build/${type}/${app}.jar | tee $DIR/push.log

STATUS=${PIPESTATUS[0]}

cf logs --recent ${app}-sample > $DIR/recent.log

ROUTE=`cf app ${app}-sample | grep urls | awk '{print $2}'`
ab -c 10 -n 100 http://$ROUTE/ | tee $DIR/ab.log

ERRORS=`grep Failed $DIR/ab.log | awk -F ':' '{print $2}'`

echo Finished: $id ${STATUS} ${ERRORS} $opts

echo $id $app $type $limit ${STATUS} ${ERRORS} >> build/result.txt
