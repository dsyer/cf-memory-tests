#!/bin/bash

echo $*

export CF_COLOR=false

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
opts=
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -Xmx${opt}M"
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -Xms${opt}M"
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -Xss${opt}K"
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -XX:MaxMetaspaceSize=${opt}M"
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -XX:MetaspaceSize=${opt}M"
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -XX:CompressedClassSpaceSize=${opt}M"
opt=${1}; shift
[ "${opt}" == "0" ] || opts="$opts -XX:ReservedCodeCacheSize=${opt}M"
mainkey=$1; shift
opts="$opts $*"

main=""
if [ "${mainkey}" == "auto" -o "${mainkey}" == "" ]; then
    mainkey=main-class
fi
rm -rf build/META-INF
(cd build/; jar -xf ${type}/${app}.jar META-INF/MANIFEST.MF)
if [ -e build/META-INF/MANIFEST.MF ]; then
    main=`grep -i ${mainkey} build/META-INF/MANIFEST.MF | awk -F ':' '{print $2}' | sed 's/\s//g'`
fi
if [ "${main}" == "" ]; then
    main='org.springframework.boot.loader.JarLauncher'
fi

if [ "${main%JarLauncher*}" == "${main}" ]; then
    lib='$PWD/BOOT-INF/classes:$PWD/BOOT-INF/lib/*:'
fi

cf delete benchmark -f -r
DIR=build/push/$id

mkdir -p $DIR
sed -e "s/%{app}/${app}/" -e "s/%{main}/${main}/" -e "s/%{memory}/${limit}/" -e "s/%{opts}/${opts}/" -e "s,%{lib},${lib}," manifest.yml.tmpl > $DIR/manifest.yml

echo Pushing ${app} with main=${main}

cf push benchmark -f $DIR/manifest.yml -p build/${type}/${app}.jar | tee $DIR/push.log

cf app benchmark > $DIR/status.txt

if grep 'requested state: stopped' $DIR/status.txt; then
    STATUS=stopped
else
    STATUS=`tail -1 $DIR/status.txt | awk '{print $2}'`
fi

cf logs --recent benchmark > $DIR/recent.log

if [ "${STATUS}" == "running" ]; then

    ROUTE=`grep routes $DIR/status.txt | awk '{print $2}'`
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
