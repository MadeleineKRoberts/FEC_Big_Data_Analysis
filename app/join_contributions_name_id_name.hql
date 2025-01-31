create table campaign_donations (
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

                                        FEC_ELECTION_YR smallint,
                                        CMTE_ID string,
                                        CMTE_TP string,
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
                                        SUB_ID int
)
    stored as avro;

INSERT OVERWRITE TABLE campaign_donations
SELECT
    d.CAND_ID AS CAND_ID,
    d.CAND_NAME as CAND_NAME,
    d.CAND_PTY_AFFILIATION as CAND_PTY_AFFILIATION,
    d.CAND_ELECTION_YR as CAND_ELECTION_YR,
    d.CAND_OFFICE_ST as CAND_OFFICE_ST,

    d.CAND_OFFICE as CAND_OFFICE,
    d.CAND_OFFICE_DISTRICT as CAND_OFFICE_DISTRICT,
    d.CAND_ICI as CAND_ICI,
    d.CAND_STATUS as CAND_STATUS,
    d.CAND_PCC as CAND_PCC,

    c.FEC_ELECTION_YR AS FEC_ELECTION_YR,
    c.CMTE_ID AS CMTE_ID,
    c.CMTE_TP AS CMTE_TP,
    c.AMNDT_IND AS AMNDT_IND,
    c.RPT_TP AS RPT_TP,

    c.TRANSACTION_PGI AS TRANSACTION_PGI,
    c.IMAGE_NUM AS IMAGE_NUM,
    c.TRANSACTION_TP AS TRANSACTION_TP,
    c.ENTITY_TP AS ENTITY_TP,
    c.NAME AS NAME,

    c.CITY AS CITY,
    c.STATE AS STATE,
    c.ZIP_CODE AS ZIP_CODE,
    c.EMPLOYER AS EMPLOYER,
    c.OCCUPATION AS OCCUPATION,

    c.TRANSACTION_DT AS TRANSACTION_DT,
    c.TRANSACTION_AMT AS TRANSACTION_AMT,
    c.OTHER_ID AS OTHER_ID,
    c.TRAN_ID AS TRAN_ID,
    c.FILE_NUM AS FILE_NUM,

    c.MEMO_CD AS MEMO_CD,
    c.MEMO_TEXT AS MEMO_TEXT,
    c.SUB_ID AS SUB_ID
FROM
    contributions_with_ids AS c JOIN candName AS d ON c.CAND_ID = d.CAND_ID and c.CAND_ELECTION_YR = d.CAND_ELECTION_YR;


