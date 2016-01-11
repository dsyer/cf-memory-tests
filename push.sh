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

if [ "${1}" == "" ]; then
    echo Skipping empty line
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
mainkey=$1; shift
opts="$opts $*"

main=""
if [ "${mainkey}" == "auto" -o "${mainkey}" == "" ]; then
    mainkey=main-class
fi
rm -rf build/META-INF
(cd build/; jar -xf ${type}/${app}.jar META-INF/MANIFEST.MF)
if [ -e build/META-INF/MANIFEST.MF ]; then
    main=`grep -i ${mainkey} build/META-INF/MANIFEST.MF | awk -F ':' '{print $2}'`
fi
if [ "${main}" == "" ]; then
    main='org.springframework.boot.loader.JarLauncher'
fi

if [ "${main%JarLauncher*}" == "${main}" ]; then
    lib='$PWD/lib/*:'
fi

cf delete benchmark -f -r
DIR=build/push/$id

mkdir -p $DIR
sed -e "s/%{app}/${app}/" -e "s/%{main}/${main}/" -e "s/%{memory}/${limit}/" -e "s/%{opts}/${opts}/" -e "s,%{lib},${lib}," manifest.yml.tmpl > $DIR/manifest.yml

echo Pushing ${app} with main=${main}

cf push benchmark -f $DIR/manifest.yml -p build/${type}/${app}.jar | tee $DIR/push.log

cf app benchmark > $DIR/status.txt

STATUS=`tail -1 $DIR/status.txt | awk '{print $2}'`

cf logs --recent benchmark > $DIR/recent.log

if [ "${STATUS}" == "running" ]; then

    ROUTE=`grep urls $DIR/status.txt | awk '{print $2}'`
    ab -c 10 -n 100 http://$ROUTE/ | tee $DIR/ab.log

    ERRORS=`egrep 'Non-2xx' $DIR/ab.log | awk -F ':' '{print $2}'`
    if [ "${ERRORS}" == "" ]; then
        ERRORS=`egrep 'Failed' $DIR/ab.log | awk -F ':' '{print $2}'`
    fi

fi

if [ "${ERRORS}" == "" ]; then
    ERRORS=0
fi

echo Finished: $id ${STATUS} ${ERRORS} $opts

echo $id $app $type $limit ${STATUS} ${ERRORS} >> build/result.txt
