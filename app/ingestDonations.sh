# Unzips donation data into HDFS
for name in *.zip
  do unzip -p $name | tail -n +2 | hdfs dfs -put - /mkroberts/donations2020/${name%.zip}.csv;
done