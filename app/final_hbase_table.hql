create external table campaign_contribution_summary (
                                                        STATEYRPP string,
                                                        CAND_OFFICE_ST string,
                                                        CAND_ELECTION_YR bigint,
                                                        CAND_PTY_AFFILIATION string,
                                                        TOTAL_DONATIONS bigint,
                                                        NUMBER_DONATIONS bigint,
                                                        IN_STATE_CONTRIBUTIONS bigint,
                                                        NUM_IN_STATE bigint,
                                                        OUT_OF_STATE_CONTRIBUTIONS bigint,
                                                        NUM_OUT_OF_STATE bigint

)
    STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
        WITH SERDEPROPERTIES ('hbase.columns.mapping' = ':key, contribution_total:CAND_OFFICE_ST,contribution_total:CAND_ELECTION_YR,contribution_total:CAND_PTY_AFFILIATION,contribution_total:TOTAL_DONATIONS#b,contribution_total:NUMBER_DONATIONS#b,contribution_total:IN_STATE_CONTRIBUTIONS#b,contribution_total:NUM_IN_STATE#b,contribution_total:OUT_OF_STATE_CONTRIBUTIONS#b,contribution_total:NUM_OUT_OF_STATE#b')
    TBLPROPERTIES ('hbase.table.name' = 'campaign_contribution_summary');


insert overwrite table campaign_contribution_summary select concat(CAND_OFFICE_ST, CAND_ELECTION_YR, CAND_PTY_AFFILIATION),
                                                            CAND_OFFICE_ST,
                                                            CAND_ELECTION_YR,
                                                            CAND_PTY_AFFILIATION,
                                                            TOTAL_DONATIONS,
                                                            NUMBER_DONATIONS,
                                                            IN_STATE_CONTRIBUTIONS,
                                                            NUM_IN_STATE,
                                                            OUT_OF_STATE_CONTRIBUTIONS,
                                                            NUM_OUT_OF_STATE
from count_sum_campaign_contributions_hive;