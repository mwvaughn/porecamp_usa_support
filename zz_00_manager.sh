#!/bin/bash

cd /work/01374/vaughn/porecamp_usa

while true
do
	date
	/work/01374/vaughn/porecamp_usa/scripts/00_sync_master.sh >> /work/01374/vaughn/porecamp_usa/logs/00_sync_master.log
	date
	sleep 900
done
