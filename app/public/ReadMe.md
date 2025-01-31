RUN APPLICATION:
Open terminal to run on 3090:
SSH to EC2: ssh -i ~/Desktop/big_data/mkroberts.pem ec2-user@ec2-3-143-113-170.us-east-2.compute.amazonaws.com
cd into project folder: cd mkroberts/app
Run: node app.js 3090 ec2-3-131-137-149.us-east-2.compute.amazonaws.com 8070 b-3.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-1.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-2.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092
node app.js 3090 ec2-3-131-137-149.us-east-2.compute.amazonaws.com 8070 b-3.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-1.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-2.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092

Open Kafka:
SHH into Hadoop:  ssh -i ~/Desktop/big_data/mkroberts.pem hadoop@ec2-3-131-137-149.us-east-2.compute.amazonaws.com
cd into kafka: cd /home/hadoop/kafka_2.12-2.8.1/bin
Run: kafka-console-consumer.sh --bootstrap-server b-1.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-3.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-2.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092 --topic mkrobertsTestRequests

Open a terminal for Spark:
SSH into Hadoop: ssh -i ~/Desktop/big_data/mkroberts.pem hadoop@ec2-3-131-137-149.us-east-2.compute.amazonaws.com -L 8070:ec2-3-131-137-149.us-east-2.compute.amazonaws.com:8070
Cd to directory where the uberjar exists: cd mkroberts/app/target
Run: spark-submit --master local[2] --driver-java-options "-Dlog4j.configuration=file:///home/hadoop/ss.log4j.properties" --class StreamContritions uber-testingFlightsArch-1.0-SNAPSHOT.jar b-2.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-1.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092,b-3.mpcs53014kafka.o5ok5i.c4.kafka.us-east-2.amazonaws.com:9092

Access the application: http://ec2-3-143-113-170.us-east-2.compute.amazonaws.com:3090/
Access the form for the speed layer: http://ec2-3-143-113-170.us-east-2.compute.amazonaws.com:3090/submitContribution.html



BUILDING THE APPLICATION PROCESS:
Step one: Choose a data set.
The data set that I chose was Federal Election Commission individual contribution data.
The main data set (within donations2020) represents individual contributions to political candidates (represented as a committee ID) in US
Federal elections. This data set is then merged with committees and political candidate names in order to link each contribution via committee ID to the 
Candidate ID, and then to the Candidate Name and Political Party.

Due to the size of the data already about 6GB and to be conscious of the use of 
the cluster, I chose to download only the individual contributions from 2020 onwards 
rather than all the data which dates back to 1980.

Open terminal window with: ssh -i ~/Desktop/big_data/mkroberts.pem hadoop@ec2-3-131-137-149.us-east-2.compute.amazonaws.com

Step two: Ingest and add data to Hadoop.
    a) Individual Donations
        Run individualDonations.sh
            This pulls the individual contribution data from the FEC websites as zip files.
        Run ingestDonation.sh
            This unzips the contributions data into HDFS.
    b) Committee Identifiers
        Run candComm.sh
            This pulls the committee identifier data from the FEC websites as zip files.
        Run ingestCC.sh
            This unzips the committee data into HDFS.
    c) Name & Party Identifiers
            Run candIDandName.sh
                This pulls the candidate name and political party identifier data from the FEC websites as 
                zip files.
            Run ingestIDNameLink.sh
                This unzips the candidate name and political party  data into HDFS.

Move to Hive: beeline -u jdbc:hive2://localhost:10000/default -n hadoop -d org.apache.hive.jdbc.HiveDriver

Step three: Move data into Hive and Hbase: 
    Processes for all the following command is as follows:
    1) Map the CSV data we downloaded in Hive
    2) Run a test queries in hive to make sure the above worked correctly.
    3) Create and populate external table in Hadoop. This table is stored as AVRO as most of the current raw 
        data is not categorical and tends to be unique across rows. So Avro's compact binary representation is the better option here and will 
        better support the map reduce functions, as it will better allow for schema evolution in this instance.
    4) Run a test queries in hadoop to make sure the above worked correctly. Once confirmed drop CSV file.

    a) Run hive_contributions.hql
        Ingests data to hive in its
    b) Run hive_commNameID.hql
    c) Run hive_candName.hql
    d) Run join_contributions_to_name_ids.hql
    e) Run join_contributions_name_id_name.hql  
    f) Run main_serving_layer_file.hql
    g) Run final_hbase_table.hql

Steps f and g create the main data set that we will use in our serving layer. The serde properties (to specify the schema on read) 
which tell hive how to decode the thrift jars are set to #B for the numbers to allow
for binary incrementation within the speed layer. In this table we reduce the columns. We group by state, year, & political 
party; thus this eliminates the individual candidates (it was too difficult for processing keys in the serving layer),
though the connection of the 3 tables was still necessary to recover the political party that the donation was going to. 
Additionally within these steps we reduce the data to sum the total number of individual contributions, total number of 
individual contributions made by individuals who live in the political candidate's state, and the total number of contributions
for those who do not. Moreover, total dollar contributions are calculated for these three categories.

For these steps, I use hive to map reduce, rather than thrift, because the sql abstraction was able to preform the simple 
commands of sum and average. Again the schema on read of hive was beneficial due to the uniqueness of each row in my data 
set. This allowed for more flexiblity and more efficient jobs.


Using Serving Layer with Application:

Application V1:
1) Modified the app.js and associated files from flights_and_weather to support my unique data structure and needs.
    Accessed the row based on the state that was entered in by the user. The removed the prefix
    from the key to retrieve year and political party of the respective contributions.
    Mapped values in campaign_contribution_summary and averages of total, in-state, and out of state contributions by party and displayed on web application.
    
2) Created an  explicit tunnel mapping port 8070 on my laptop to port 8070 on the main node of the cluster: ssh -i ~/Desktop/big_data/mkroberts.pem hadoop@ec2-3-131-137-149.us-east-2.compute.amazonaws.com -L 8070:ec2-3-131-137-149.us-east-2.compute.amazonaws.com:8070
3) Load the template and rendered the functioning application on http://localhost:3000/ 
4) Tested out that the listener at app.listen(port) worked
5) Success!

Application V2:
1) Configured app.js properties pf the application to run on the webserver (Port 3090)
2) Moved to cluster (without tunnel) and NPM installed
3) Success!

create form

Application V3:
1) Created table for speed layer in habase: create "latest_contributions", "contribution" to hold inputted data.
2) Opened a new project and configured the deployment properties to ensure it would create the uber jar in mkroberts/app
    on the hadoop cluster. 
3) Build scala files: StreamContributions.scala and AdditionalContribution.scala 
4) Maven installed to create the uber jar files 
5) Deployed to cluster
6) Ran application with additional terminal window running Spark to observe the inputted values

Run app.js
Observed here: http://ec2-3-143-113-170.us-east-2.compute.amazonaws.com:3090/


Speed layer:
I built the form in http://ec2-3-143-113-170.us-east-2.compute.amazonaws.com:3090/submitContribution.html to allow for
individual to enter in contributions. This will not be integrated into the batch layer because they may not be completely correct
however it will provide some insight as the FEC irregularly update their data sets.








