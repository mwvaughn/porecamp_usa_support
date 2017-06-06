#!/bin/bash

cd /work/01374/vaughn/porecamp_usa

while true
do
	date
	/work/01374/vaughn/porecamp_usa/scripts/02_submit_batches.sh >> /work/01374/vaughn/porecamp_usa/logs/02_submit_batches.log
	date
	sleep 1200
done
