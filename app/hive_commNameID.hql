-- This file will create an ORC table with flight ontime arrival data

-- First, map the CSV data we downloaded in Hive
create external table comm_name_to_id_csv(
                                             CAND_ID string,
                                             CAND_ELECTION_YR int,
                                             FEC_ELECTION_YR int,
                                             CMTE_ID string,
                                             CMTE_TP string,
                                             CMTE_DSGN string,
                                             LINKAGE_ID int)
    row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'

        WITH SERDEPROPERTIES (
        "separatorChar" = "|",
        "quoteChar"     = "\""
        )
    STORED AS TEXTFILE
    location '/mkroberts/committees'; -- should be renamed

-- Run a test query to make sure the above worked correctly
select CAND_ID, CAND_ELECTION_YR, FEC_ELECTION_YR, CMTE_ID, CMTE_TP, CMTE_DSGN, LINKAGE_ID from comm_name_to_id_csv limit 5;
select count(1) from comm_name_to_id_csv;
select distinct(fec_election_yr) from comm_name_to_id_csv order by 1 desc;

-- Create an ORC table for ontime data (Note "stored as ORC" at the end)
create table comm_name_to_id(
                                CAND_ID string,
                                CAND_ELECTION_YR smallint,
                                FEC_ELECTION_YR smallint,
                                CMTE_ID string,
                                CMTE_TP string,
                                CMTE_DSGN string,
                                LINKAGE_ID int)
    stored as orc;

-- Copy the CSV table to the ORC table
insert overwrite table comm_name_to_id select * from comm_name_to_id_csv;