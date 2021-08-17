#!/bin/bash
oc create secret generic github --from-env-file=secret/.git-credentials --type=kubernetes.io/basic-auth
oc annotate secret github 'build.openshift.io/source-secret-match-uri-1=https://github.com/we-r-devs/order-api-node-docker.git'
oc apply -f docker-iac.yaml