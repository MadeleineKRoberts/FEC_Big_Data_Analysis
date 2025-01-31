-- This file will create an ORC table with flight ontime arrival data

-- First, map the CSV data we downloaded in Hive
create external table indiv_donations_csv(
                                    CMTE_ID string,
                                    AMNDT_IND string,
                                    RPT_TP string,
                                    TRANSACTION_PGI string,
                                    IMAGE_NUM string,
                                    TRANSACTION_TP string,
                                    ENTITY_TP string,
                                    NAME string,
                                    CITY string,
                                    STATE string,
                                    ZIP_CODE string,
                                    EMPLOYER string,
                                    OCCUPATION string,
                                    TRANSACTION_DT string,
                                    TRANSACTION_AMT decimal,
                                    OTHER_ID string,
                                    TRAN_ID string,
                                    FILE_NUM int,
                                    MEMO_CD string,
                                    MEMO_TEXT string,
                                    SUB_ID int)
    row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'

        WITH SERDEPROPERTIES (
        "separatorChar" = "|",
        "quoteChar"     = "\""
        )
    STORED AS TEXTFILE
    location '/mkroberts/donations2020';

-- Run a test query to make sure the above worked correctly
select year,month,dayofmonth,carrier,origin,origincityname,dest,depdelay,arrdelay from ontime_csv limit 5;

-- Create an ORC table for ontime data (Note "stored as ORC" at the end)
create table indiv_donations(
                          CMTE_ID string,
                          AMNDT_IND string,
                          RPT_TP string,
                          TRANSACTION_PGI string,
                          IMAGE_NUM string,
                          TRANSACTION_TP string,
                          ENTITY_TP string,
                          NAME string,
                          CITY string,
                          STATE string,
                          ZIP_CODE string,
                          EMPLOYER string,
                          OCCUPATION string,
                          TRANSACTION_DT string,
                          TRANSACTION_AMT decimal,
                          OTHER_ID string,
                          TRAN_ID string,
                          FILE_NUM int,
                          MEMO_CD string,
                          MEMO_TEXT string,
                          SUB_ID int)
    stored as avro;

-- Copy the CSV table to the ORC table
insert overwrite table indiv_donations select * from indiv_donations_csv where TRANSACTION_AMT is not null and (ZIP_CODE is not null or STATE is not null);