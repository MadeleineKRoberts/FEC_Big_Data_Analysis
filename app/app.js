'use strict';
const http = require('http');
var assert = require('assert');
const express= require('express');
const app = express();
const mustache = require('mustache');
const filesystem = require('fs');
const url = require('url');
const port = Number(process.argv[2]);

const hbase = require('hbase')
var hclient = hbase({ host: process.argv[3], port: Number(process.argv[4]), encoding: 'latin1'})


hclient.table('campaign_contribution_summary').row('MN2020DEM').get((error, value) => {
	console.info(rowToMap(value))
	console.info(value)
})

function counterToNumber(c) {
	var num = Number(Buffer.from(c).readBigInt64BE());
	return num;
}
function rowToMap(row) {
	var stats = {}
	row.forEach(function (item) {
		if (item['$'].length < 5) {
			stats[item['column']] = item['$'];

		}
		else {
			stats[item['column']] = counterToNumber(item['$'])
		}

	});
	return stats;
}

function mapToTemplate(row) {
		//console.info(row)
		console.info()

		let candIDYear  = { candIDYR : row['contribution_total:CAND_ID'] + '_' + row['contribution_total:CAND_ELECTION_YR'] };
		candIDYear['name'] = row['contribution_total:CAND_NAME'];
		candIDYear['state'] = row['contribution_total:CAND_OFFICE_ST'];
		candIDYear['yr'] = row['contribution_total:CAND_ELECTION_YR'];
		candIDYear['pp'] = row['contribution_total:CAND_PTY_AFFILIATION'];
		candIDYear['total_money'] = row['contribution_total:TOTAL_DONATIONS'];
		candIDYear['total_donation_num'] = row['contribution_total:NUMBER_DONATIONS'];
		candIDYear['av_donation'] = calc_average("NUMBER_DONATIONS","TOTAL_DONATIONS", row);
		candIDYear['in_state'] = calc_average("NUMBER_DONATIONS", "NUM_IN_STATE", row);
		candIDYear['av_in_state'] = calc_average("NUM_IN_STATE", "IN_STATE_CONTRIBUTIONS", row);
		candIDYear['av_out_state'] = calc_average("NUM_OUT_OF_STATE", "OUT_OF_STATE_CONTRIBUTIONS", row)

		return candIDYear;
}


function calc_average(a, b, c) {
	var numDonations = c["contribution_total:" + a];
	var quantDonations = c["contribution_total:" + b];
	if(numDonations == 0)
		return " - ";
	return (quantDonations/numDonations).toFixed(1); /* One decimal place */
}


hclient.table('campaign_contribution_summary').scan(
	{
		filter: {
			type: "PrefixFilter",
			value: "MN"
		},
		maxVersions: 1
	},
	function (err, cells) {
		console.info(cells);
		console.info(typeof cells);

		if (Array.isArray(cells)) {
			for (let i = 0; i < cells.length / 13; i++) {
				const startIdx = i * 13;
				const endIdx = startIdx + 13;

				// Extract a set of 13 columns using slice
				const currentSet = cells.slice(startIdx, endIdx);

				// Log the result of rowToMap for the current set
				console.info(rowToMap(currentSet));
			}
		}
		else {
			console.error("cells is not an array");
		}
		//console.info(groupByYear("ORD", cells));
	})





app.use(express.static('public'));
app.get('/delays.html',function (req, res) {
    //const route=req.query['origin'] + req.query['dest'];
	const route=req.query['origin']
    console.log(route);


	hclient.table('campaign_contribution_summary').scan(
		{
			filter: {
				type: "PrefixFilter",
				value: route
			},
			maxVersions: 1
		},
		function (err, cells) {
			if (err) {
				console.error(err);
				return;
			}

			console.info(cells);
			console.info(typeof cells);
			let result = [];

			if (Array.isArray(cells)) {

				for (let i = 0; i < cells.length / 9; i++) {
					const startIdx = i * 9;
					const endIdx = startIdx + 9;

					// Extract a set of 13 columns using slice
					const currentSet = cells.slice(startIdx, endIdx);


					// Log the result of rowToMap for the current set
					console.info( rowToMap(currentSet));
					const mapSet = rowToMap(currentSet);
					result.push(mapToTemplate(mapSet));
				}
			} else {
				console.error("cells is not an array");
			}

			// Read the template file
			var template = filesystem.readFileSync("result.mustache").toString();
			console.info("here")
				// Create input for the template
			let input = { yearly_averages: result };

			// Render the template with the input data
			let html = mustache.render(template, input);

			// Send the HTML response
			res.send(html);
	});
});

/* Send simulated weather to kafka */
var kafka = require('kafka-node');
var Producer = kafka.Producer;
var KeyedMessage = kafka.KeyedMessage;
var kafkaClient = new kafka.KafkaClient({kafkaHost: process.argv[5]});
var kafkaProducer = new Producer(kafkaClient);



app.get('/weather.html',function (req, res) {

	 var party = req.query['pp'];
	 var state = req.query['state'];
	 var year = req.query['yr'];

	 var rowName = state + year + party;

	 var num_in_state = 0;
	 var num_out_of_state = 0;
	 var total_donations = req.query['donation_amount'];
	 var number_donations = 1;
	 var in_state_contributions = 0;
	 var out_of_state_contributions = 0;

	 var in_state = (req.query['in_state']) ? true : false;

	 if (in_state) {
		 num_in_state = 1;
		 in_state_contributions = req.query['donation_amount'];
	 }
	 else {
		 num_out_of_state = 1;
		 out_of_state_contributions = req.query['donation_amount'];
	 }

	 var report = {
		 rowReference : rowName,
		 num_in_state : num_in_state,
		 num_out_of_state : num_out_of_state,
		 total_donations: total_donations,
		 number_donations : number_donations,
		 in_state_contributions : in_state_contributions,
		 out_of_state_contributions : out_of_state_contributions

	};

	kafkaProducer.send([{ topic: 'mkrobertsTestRequests', messages: JSON.stringify(report)}],
		function (err, data) {
			console.log(err);
			console.log(report);
			res.redirect('submitContribution.html');
		});
});

app.listen(port);
