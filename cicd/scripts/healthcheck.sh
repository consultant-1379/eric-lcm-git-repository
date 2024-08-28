#! /bin/bash
#
# COPYRIGHT Ericsson 2022
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#

DEPLOYMENT_NAMES="/tmp/deploy_names"
DEPLOYMENT_NOTREADY_NAMES="/tmp/deploy_notready_names"
STATEFULSET_NAMES="/tmp/sts_names"
STATEFULSET_NOTREADY_NAMES="/tmp/sts_notready_names"

rm -rf $DEPLOYMENT_NAMES $DEPLOYMENT_NOTREADY_NAMES $STATEFULSET_NAMES $STATEFULSET_NOTREADY_NAMES 
touch $DEPLOYMENT_NOTREADY_NAMES $STATEFULSET_NOTREADY_NAMES

kubectl -n $K8S_NAMESPACE get deployment --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'|egrep -v "^tc|^negative" > $DEPLOYMENT_NAMES
kubectl -n $K8S_NAMESPACE get statefulset --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' > $STATEFULSET_NAMES

count=0
while true; do
    if [ -s $DEPLOYMENT_NAMES ]; then
        cat $DEPLOYMENT_NAMES | while read deploymentname
        do
            desiredreplicas="$(kubectl -n $K8S_NAMESPACE get deployment $deploymentname -o "jsonpath='{.spec.replicas}'")"
            availablereplicas="$(kubectl -n $K8S_NAMESPACE get deployment $deploymentname -o "jsonpath='{.status.readyReplicas}'")"
            echo "Deployment Name:$deploymentname Desired Replicas:$desiredreplicas Available Replicas:$availablereplicas"
            if [ ${desiredreplicas} != ${availablereplicas} ]; then 
                echo $deploymentname >> $DEPLOYMENT_NOTREADY_NAMES
            fi 
        done

        mv $DEPLOYMENT_NOTREADY_NAMES $DEPLOYMENT_NAMES
        touch $DEPLOYMENT_NOTREADY_NAMES
    fi

    if [ -s $STATEFULSET_NAMES ]; then
        cat $STATEFULSET_NAMES | while read statefulsetname
        do
            desiredreplicas="$(kubectl -n $K8S_NAMESPACE get statefulset $statefulsetname -o "jsonpath='{.spec.replicas}'")"
            availablereplicas="$(kubectl -n $K8S_NAMESPACE get statefulset $statefulsetname -o "jsonpath='{.status.readyReplicas}'")"
            echo "Statefulset Name:$statefulsetname Desired Replicas:$desiredreplicas Available Replicas:$availablereplicas"
            if [ ${desiredreplicas} != ${availablereplicas} ]; then 
                echo $statefulsetname >> $STATEFULSET_NOTREADY_NAMES
            fi 
        done

        mv $STATEFULSET_NOTREADY_NAMES $STATEFULSET_NAMES
        touch $STATEFULSET_NOTREADY_NAMES
    fi

    if [ ! -s $DEPLOYMENT_NAMES ] && [ ! -s $STATEFULSET_NAMES ]; then
        echo "All Deployments and Statefulsets are up and running"
        exit 0
    fi

    if [[ "$count" -gt 30 ]]; then
       echo "TIMEOUT"; 
       exit 1
    fi
    echo Check: $count
    sleep 10
    ((count++))
done