#!/bin/bash
ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
if [[ -n "${ip}" ]]; then
    echo "${ip}"
else
    echo 'NA'
fi
