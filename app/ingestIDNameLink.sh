# Unzips donation data into HDFS
for name in *.zip
  do unzip -p $name | tail -n +2 | hdfs dfs -put - /mkroberts/names/${name%.zip}.csv;
done