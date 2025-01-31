create external table count_sum_campaign_contributions_hive_temp (
                                                                     CAND_PTY_AFFILIATION string,
                                                                     CAND_ELECTION_YR int,
                                                                     CAND_OFFICE_ST string,
                                                                     TOTAL_DONATIONS decimal,
                                                                     NUMBER_DONATIONS int,
                                                                     IN_STATE_CONTRIBUTIONS decimal,
                                                                     NUM_IN_STATE int

)
    stored as avro;


INSERT OVERWRITE TABLE count_sum_campaign_contributions_hive_temp
SELECT
    CAND_PTY_AFFILIATION,
    CAND_ELECTION_YR,
    CAND_OFFICE_ST,
    SUM(TRANSACTION_AMT) AS TOTAL_DONATIONS,
    COUNT(1) AS NUMBER_DONATIONS,
    SUM(CASE WHEN STATE = CAND_OFFICE_ST THEN TRANSACTION_AMT ELSE 0 END ) AS IN_STATE_CONTRIBUTIONS,
    COUNT(CASE WHEN STATE = CAND_OFFICE_ST THEN 1 ELSE NULL END ) AS NUM_IN_STATE
FROM
    campaign_donations
GROUP BY
    CAND_PTY_AFFILIATION,
    CAND_ELECTION_YR,
    CAND_OFFICE_ST;


// this is the next step
create external table count_sum_campaign_contributions_hive (
                                                  CAND_PTY_AFFILIATION string,
                                                  CAND_ELECTION_YR int,
                                                  CAND_OFFICE_ST string,
                                                  TOTAL_DONATIONS decimal,
                                                  NUMBER_DONATIONS int,
                                                  IN_STATE_CONTRIBUTIONS decimal,
                                                  NUM_IN_STATE int,
                                                  OUT_OF_STATE_CONTRIBUTIONS decimal,
                                                  NUM_OUT_OF_STATE int

)
    stored as avro;


INSERT OVERWRITE TABLE
SELECTcount_sum_campaign_contributions_hive
    CAND_PTY_AFFILIATION,
    CAND_ELECTION_YR,
    CAND_OFFICE_ST,
    TOTAL_DONATIONS,
    NUMBER_DONATIONS,
    IN_STATE_CONTRIBUTIONS,
    NUM_IN_STATE,
    (TOTAL_DONATIONS - IN_STATE_CONTRIBUTIONS) AS OUT_OF_STATE_CONTRIBUTIONS,
    (NUMBER_DONATIONS - NUM_IN_STATE) AS NUM_OUT_OF_STATE
FROM
    count_sum_campaign_contributions_hive_temp;


