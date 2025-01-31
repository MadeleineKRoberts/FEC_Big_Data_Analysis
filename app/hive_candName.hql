-- First, map the CSV data we downloaded in Hive
create external table cand_id_to_name(
                                             CAND_ID string,
                                             CAND_NAME string,
                                             CAND_PTY_AFFILIATION string,
                                             CAND_ELECTION_YR int,
                                             CAND_OFFICE_ST string,
                                             CAND_OFFICE string,
                                             CAND_OFFICE_DISTRICT string,
                                             CAND_ICI string,
                                             CAND_STATUS string,
                                             CAND_PCC string,
                                             CAND_ST1 int,
                                             CAND_ST2 string,
                                             CAND_CITY string,
                                             CAND_ST string,
                                             CAND_ZIP string)
    row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'

        WITH SERDEPROPERTIES (
        "separatorChar" = "|",
        "quoteChar"     = "\""
        )
    STORED AS TEXTFILE
    location '/mkroberts/candidateNames'; -- check this

-- Run a test query to make sure the above worked correctly
select CAND_NAME, cand_election_yr from cand_id_to_name limit 20;
select count(distinct cand_name), count(1) as number_rows from cand_id_to_name;

-- Create an ORC table for ontime data (Note "stored as ORC" at the end)
create table candName(
                                CAND_ID string,
                                CAND_NAME string,
                                CAND_PTY_AFFILIATION string,
                                CAND_ELECTION_YR int,
                                CAND_OFFICE_ST string,
                                CAND_OFFICE string,
                                CAND_OFFICE_DISTRICT string,
                                CAND_ICI string,
                                CAND_STATUS string,
                                CAND_PCC string)
    stored as orc;

-- Copy the CSV table to the ORC table
insert overwrite table candName select CAND_ID, CAND_NAME, CAND_PTY_AFFILIATION, CAND_ELECTION_YR, CAND_OFFICE_ST, CAND_OFFICE, CAND_OFFICE_DISTRICT, CAND_ICI, CAND_STATUS, CAND_PCC  from cand_id_to_name;