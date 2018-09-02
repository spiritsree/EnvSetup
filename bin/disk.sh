#!/bin/bash
 df -Ph | awk '{if ($6 == "/") print $0;}' | awk '{ print $4 }'
