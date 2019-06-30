<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>NTP Daemon</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p{
font-weight: bolder;
}
</style>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/ntpmerlin/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/chart.min.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<!--<script language="JavaScript" type="text/javascript" src="/ext/ntpjitter.js"></script>
<script>
var lineDataOffset;
var myLineChart;
Chart.defaults.global.defaultFontColor = "#CCC";

function redraw()
{
	lineDataOffset = [];
	GenChartDataJitter();
	draw_chart();
}

function draw_chart(){
	if (myLineChart != undefined) myLineChart.destroy();
	var ctx = document.getElementById("chart").getContext("2d");
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: true, text: "Offset" },
		tooltips: {
			callbacks: {
					title: function (tooltipItem, data) { return (moment(tooltipItem[0].xLabel).format('YYYY-MM-DD HH:mm')); },
					label: function (tooltipItem, data) { return data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y.toString() + ' ms';}
				}
		},
		scales: {
			xAxes: [{
				type: "time",
				gridLines: { display: true, color: "#282828" },
				ticks: {
					display: true
				},
				time: { min: moment().subtract(24, "hours"), unit: "hour", stepSize: 1 }
			}],
			yAxes: [{
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: "Offset" },
				ticks: {
					display: true,
					callback: function (value, index, values) {
						return value + ' ms';
					}
				},
			}]
		}
	};
	var lineDataset = {
		datasets: [{data: lineDataOffset,
			label: "Offset",
			borderWidth: 1,
			pointRadius: 1,
			fill: false,
			backgroundColor: "#fc8500",
			borderColor: "#fc8500",
		}]
	};
	myLineChart = new Chart(ctx, {
		type: 'line',
		options: lineOptions,
		data: lineDataset
	});
}
function initial(){
show_menu();
redraw();
}
function reload() {
location.reload(true);
}
function applyRule() {
var action_script_tmp = "start_ntpmerlin";
document.form.action_script.value = action_script_tmp;
document.form.submit();
}
function getRandomColor() {
var r = Math.floor(Math.random() * 255);
var g = Math.floor(Math.random() * 255);
var b = Math.floor(Math.random() * 255);
return "rgba(" + r + "," + g + "," + b + ", 1)";
}
function poolColors(a) {
var pool = [];
for(i = 0; i < a; i++) {
	pool.push(getRandomColor());
}
return pool;
}-->
<script>
function initial(){
show_menu();
}
function reload() {
location.reload(true);
}
function applyRule() {
var action_script_tmp = "start_ntpmerlin";
document.form.action_script.value = action_script_tmp;
document.form.submit();
}
</script>
</head>
<body onload="initial();" onunLoad="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="Feedback_Info.asp">
<input type="hidden" name="next_page" value="Feedback_Info.asp">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="start_ntpmerlin">
<input type="hidden" name="action_wait" value="5">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div></td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td valign="top">
<table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tbody>
<tr bgcolor="#4D595D">
<td valign="top">
<div>&nbsp;</div>
<div class="formfonttitle">NTP Daemon Performance Stats</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<tr class="apply_gen" valign="top" height="35px">
<td>
<input type="button" onClick="applyRule();" value="Update stats" class="button_gen" name="button">
</td>
</tr>
<thead>
<tr>
<td colspan="2">Last 24 Hours</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center">
<!--<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="chart" height="120"></div>-->
<img src="/ext/ntpmerlin/offset.png">
<img src="/ext/ntpmerlin/sysjit.png">
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead>
<tr>
<td colspan="2">Last 7 Days</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center">
<img src="/ext/ntpmerlin/week-offset.png">
<img src="/ext/ntpmerlin/week-sysjit.png">
<img src="/ext/ntpmerlin/week-freq.png">
</td>
</tr>
</table>
</td>
</tr>
</tbody>
</table>
</form>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
<div id="footer">
</div>
</body>
</html>
