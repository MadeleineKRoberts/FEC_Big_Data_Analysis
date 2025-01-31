create external table mkroberts_hw42 (
                                         origin_name string,
                                         clear_flights bigint, clear_delays bigint,
                                         fog_flights bigint, fog_delay bigint,
                                         rain_flights bigint, rain_delay bigint,
                                         snow_flights bigint, snow_delay bigint,
                                         hail_flights bigint, hail_delay bigint,
                                         thunder_flights bigint, thunder_delay bigint,
                                         tornado_flights bigint, tornado_delay bigint)
    STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
        WITH SERDEPROPERTIES ('hbase.columns.mapping' = ':key,delay:clear_flights#b,delay:clear_delays#b,delay:fog_flights#b,delay:fog_delays#b,delay:rain_flights#b,delay:rain_delays#b,delay:snow_flights#b,delay:snow_delays#b,delay:hail_flights#b,delay:hail_delays#b,delay:thunder_flights#b,delay:thunder_delays#b,delay:tornado_flights#b,delay:tornado_delays#b')
    TBLPROPERTIES ('hbase.table.name' = 'mkroberts_hw42');




insert overwrite table mkroberts_hw42
select origin_name,
       SUM(clear_flights) as clear_flights, SUM(clear_delays) as clear_delays,
       SUM(fog_flights) as fog_flights, SUM(fog_delays) as fog_delays,
       SUM(rain_flights) as rain_flights, SUM(rain_delays) as rain_delays,
       SUM(snow_flights) as snow_flights, SUM(snow_delays) as snow_delays,
       SUM(hail_flights) as hail_flights, SUM(hail_delays) as hail_delays,
       SUM(thunder_flights) as thunder_flights, SUM(thunder_delays) as thunder_delays,
       SUM(tornado_flights) as tornado_flights, SUM(tornado_delays) as tornado_delays from route_delays group by origin_name;
