#!/bin/bash
mkdir mkroberts/candidateNameData
cd candidateNameData

year=2000

while [ "$year" -le 2024 ]
do
    shortYear=$(printf "%02d" $((year % 100)))
    wget "https://www.fec.gov/files/bulk-downloads/$year/cn$shortYear.zip"

    ((year+=2))
done