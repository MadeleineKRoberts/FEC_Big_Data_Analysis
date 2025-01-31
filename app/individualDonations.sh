#!/bin/bash
mkdir mkroberts/donations2020
cd mkroberts/donations2020

year=2020 

while [ "$year" -le 2022 ]
do
    shortYear=$(printf "%02d" $((year % 100)))
    wget "https://www.fec.gov/files/bulk-downloads/$year/indiv$shortYear.zip"
    ((year+=2))
done

