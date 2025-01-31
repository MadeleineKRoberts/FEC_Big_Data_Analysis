# Unzips committee & candidate ID data into HDFS
for name in *.zip
  do unzip -p $name | tail -n +2 | hdfs dfs -put - /mkroberts/committees/${name%.zip}.csv;
done