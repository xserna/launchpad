#!/usr/bin/env bash

# Check if missing template folder
DESTINATION_EZ="/ezsolr/server/ez"
DESTINATION_TEMPLATE="${DESTINATION_EZ}/template"
if [ ! -d ${DESTINATION_TEMPLATE} ]; then
    cd $PROJECTMAPPINGFOLDER/ezplatform
    mkdir -p ${DESTINATION_TEMPLATE}
    cp -R vendor/ezsystems/ezplatform-solr-search-engine/lib/Resources/config/solr/* ${DESTINATION_TEMPLATE}
fi

mkdir -p ${DESTINATION_EZ}
if [ ! -f ${DESTINATION_EZ}/solr.xml ]; then
    cp /opt/solr/server/solr/solr.xml ${DESTINATION_EZ}
    cp /opt/solr/server/solr/configsets/_default/conf/{currency.xml,solrconfig.xml,stopwords.txt,synonyms.txt,elevate.xml} ${DESTINATION_TEMPLATE}
    sed -i.bak '/<updateRequestProcessorChain name="add-unknown-fields-to-the-schema".*/,/<\/updateRequestProcessorChain>/d' ${DESTINATION_TEMPLATE}/solrconfig.xml
    sed -i -e 's/<maxTime>${solr.autoSoftCommit.maxTime:-1}<\/maxTime>/<maxTime>${solr.autoSoftCommit.maxTime:20}<\/maxTime>/g' ${DESTINATION_TEMPLATE}/solrconfig.xml
    sed -i -e 's/<dataDir>${solr.data.dir:}<\/dataDir>/<dataDir>\/opt\/solr\/data\/${solr.core.name}<\/dataDir>/g' ${DESTINATION_TEMPLATE}/solrconfig.xml
fi

SOLR_CORES=${SOLR_CORES:-collection1}
CREATE_CORES=false

for core in $SOLR_CORES
do
    if [ ! -d ${DESTINATION_EZ}/${core} ]; then
        CREATE_CORES=true
        echo "Found missing core: ${core}"
    fi
done

if [ "$CREATE_CORES" = true ]; then
    echo "Start solr on background to create missing cores"
    /opt/solr/bin/solr -s ${DESTINATION_EZ}

    for core in $SOLR_CORES
    do
        if [ ! -d ${DESTINATION_EZ}/${core} ]; then
            /opt/solr/bin/solr create_core -c ${core}  -d ${DESTINATION_TEMPLATE}
            echo "Core ${core} created."
        fi
    done
    echo "Stop background solr"
    /opt/solr/bin/solr stop
fi

/opt/solr/bin/solr -s ${DESTINATION_EZ} -f
