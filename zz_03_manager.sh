#!/bin/bash

cd /work/01374/vaughn/porecamp_usa

while true
do
	date
	/work/01374/vaughn/porecamp_usa/scripts/03_sync_completed.sh >> /work/01374/vaughn/porecamp_usa/logs/03_sync_completed.log
	date
	sleep 1800
done
