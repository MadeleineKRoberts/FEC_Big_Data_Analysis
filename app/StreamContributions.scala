import org.apache.kafka.common.serialization.StringDeserializer
import org.apache.spark.SparkConf
import org.apache.spark.streaming._
import org.apache.spark.streaming.kafka010.ConsumerStrategies.Subscribe
import org.apache.spark.streaming.kafka010.LocationStrategies.PreferConsistent
import org.apache.spark.streaming.kafka010._
import com.fasterxml.jackson.databind.{ DeserializationFeature, ObjectMapper }
import com.fasterxml.jackson.module.scala.experimental.ScalaObjectMapper
import com.fasterxml.jackson.module.scala.DefaultScalaModule
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.hbase.TableName
import org.apache.hadoop.hbase.HBaseConfiguration
import org.apache.hadoop.hbase.client.ConnectionFactory
import org.apache.hadoop.hbase.client.Get
import org.apache.hadoop.hbase.client.Increment
import org.apache.hadoop.hbase.util.Bytes

object StreamContributions {
  val mapper = new ObjectMapper()
  mapper.registerModule(DefaultScalaModule)
  val hbaseConf: Configuration = HBaseConfiguration.create()
  hbaseConf.set("hbase.zookeeper.property.clientPort", "2181")
  hbaseConf.set("hbase.zookeeper.quorum", "localhost")
  
  val hbaseConnection = ConnectionFactory.createConnection(hbaseConf)
  val campaign_contribution_summary = hbaseConnection.getTable(TableName.valueOf("campaign_contribution_summary"))
  val latestContributions = hbaseConnection.getTable(TableName.valueOf("latest_contributions"))
  
  def getLatestContributions(rowReference: String) = {
      val result = latestContributions.get(new Get(Bytes.toBytes(rowReference)))
      System.out.println(result.isEmpty())
      if(result.isEmpty())
        None
      else
        Some(AdditionalContribution(
              rowReference,
              Bytes.toInt(result.getValue(Bytes.toBytes("contribution"), Bytes.toBytes("num_in_state"))),
              Bytes.toInt(result.getValue(Bytes.toBytes("contribution"), Bytes.toBytes("num_out_of_state"))),
              Bytes.toInt(result.getValue(Bytes.toBytes("contribution"), Bytes.toBytes("total_donations"))),
              Bytes.toInt(result.getValue(Bytes.toBytes("contribution"), Bytes.toBytes("number_donations"))),
              Bytes.toInt(result.getValue(Bytes.toBytes("contribution"), Bytes.toBytes("in_state_contributions"))),
              Bytes.toInt(result.getValue(Bytes.toBytes("contribution"), Bytes.toBytes("out_of_state_contributions")))))
  }
  
  def incrementContributions(kfr : AdditionalContribution) : String = {
    val maybeLatestContributions = getLatestContributions(kfr.rowReference)

    if(maybeLatestContributions.isEmpty)
      return "No Contributions for " + kfr.rowReference;

    val latestContributions = maybeLatestContributions.get
    val inc = new Increment(Bytes.toBytes(kfr.rowReference))

    if(latestContributions.number_donations != 0) {
      inc.addColumn(Bytes.toBytes("contribution_total"), Bytes.toBytes("NUMBER_DONATIONS"), 1)
      inc.addColumn(Bytes.toBytes("contribution_total"), Bytes.toBytes("TOTAL_DONATIONS"), kfr.total_donations)
    }
    if(latestContributions.num_in_state != 0) {
      inc.addColumn(Bytes.toBytes("contribution_total"), Bytes.toBytes("NUM_IN_STATE"), 1)
      inc.addColumn(Bytes.toBytes("contribution_total"), Bytes.toBytes("IN_STATE_CONTRIBUTIONS"), kfr.in_state_contributions)
    }
    if(latestContributions.num_out_of_state != 0) {
      inc.addColumn(Bytes.toBytes("contribution_total"), Bytes.toBytes("NUM_OUT_OF_STATE"), 1)
      inc.addColumn(Bytes.toBytes("contribution_total"), Bytes.toBytes("OUT_OF_STATE_CONTRIBUTIONS"), kfr.out_of_state_contributions)
    }

    campaign_contribution_summary.increment(inc)
    return "Updated speed layer for " + kfr.rowReference
  }
  
  def main(args: Array[String]) {
    if (args.length < 1) {
      System.err.println(s"""
        |Usage: StreamContributions <brokers>
        |  <brokers> is a list of one or more Kafka brokers
        | 
        """.stripMargin)
      System.exit(1)
    }
    
    val Array(brokers) = args

    // Create context with 2 second batch interval
    val sparkConf = new SparkConf().setAppName("StreamContributions")
    val ssc = new StreamingContext(sparkConf, Seconds(2))

    // Create direct kafka stream with brokers and topics
    val topicsSet = Set("mkrobertsTestRequests")
    // Create direct kafka stream with brokers and topics
    val kafkaParams = Map[String, Object](
      "bootstrap.servers" -> brokers,
      "key.deserializer" -> classOf[StringDeserializer],
      "value.deserializer" -> classOf[StringDeserializer],
      "group.id" -> "use_a_separate_group_id_for_each_stream",
      "auto.offset.reset" -> "latest",
      "enable.auto.commit" -> (false: java.lang.Boolean)
    )
    val stream = KafkaUtils.createDirectStream[String, String](
      ssc, PreferConsistent,
      Subscribe[String, String](topicsSet, kafkaParams)
    )

    // Get the lines, split them into words, count the words and print
    val serializedRecords = stream.map(_.value);
    serializedRecords.print()

    val kfrs = serializedRecords.map(rec => mapper.readValue(rec, classOf[AdditionalContribution]))

    // Update speed table    
    val processedContributions = kfrs.map(incrementContributions)
    processedContributions.print()
    // Start the computation
    ssc.start()
    ssc.awaitTermination()
  }
}
