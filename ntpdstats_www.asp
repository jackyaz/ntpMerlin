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
<script language="JavaScript" type="text/javascript" src="/ext/ntpmerlin/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/ntpmerlin/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/ntpmerlin/ntpstatsdata.js"></script>
<script>
var LineChartOffsetDaily,LineChartJitterDaily,LineChartDriftDaily;
Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates) {
  return coordinates;
};

function Draw_Chart(txtchartname,objchartname,txtdataname,objdataname,txttitle,txtunit,colourname){
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("div"+txtchartname).getContext("2d");
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: true, text: txttitle },
		tooltips: {
			callbacks: {
					title: function (tooltipItem, data) { return (moment(tooltipItem[0].xLabel).format('YYYY-MM-DD HH:mm:ss')); },
					label: function (tooltipItem, data) { return data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y.toString() + ' ' + txtunit;}
				},
				mode: 'point',
				position: 'cursor',
				intersect: true
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
				scaleLabel: { display: false, labelString: txttitle },
				ticks: {
					display: true,
					callback: function (value, index, values) {
						return value + ' ' + txtunit;
					}
				},
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: true,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - 86400000,
						y: getLimit(txtdataname,"y","min") - Math.sqrt(Math.pow(getLimit(txtdataname,"y","min"),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(txtdataname,"y","max") + getLimit(txtdataname,"y","max")*0.1,
					},
				},
				zoom: {
					// Boolean to enable zooming
					enabled: true,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - 86400000,
						y: getLimit(txtdataname,"y","min") - Math.sqrt(Math.pow(getLimit(txtdataname,"y","min"),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(txtdataname,"y","max") + getLimit(txtdataname,"y","max")*0.1,
					},
					speed: 0.1
				}
			}
		}
	};
	var lineDataset = {
		datasets: [{data: objdataname,
			label: txttitle,
			borderWidth: 1,
			pointRadius: 1,
			lineTension: 0,
			fill: false,
			backgroundColor: colourname,
			borderColor: colourname,
		}]
	};
	objchartname = new Chart(ctx, {
		type: 'line',
		options: lineOptions,
		data: lineDataset
	});
}

function getLimit(datasetname,axis,maxmin) {
	limit=0;
	eval("limit=Math."+maxmin+".apply(Math, "+datasetname+".map(function(o) { return o."+axis+";} ))");
	return limit;
}

function RedrawAllCharts() {
	Draw_Chart("LineChartOffsetDaily",LineChartOffsetDaily,"DataOffsetDaily",DataOffsetDaily,"Offset","ms","#fc8500");
	Draw_Chart("LineChartJitterDaily",LineChartJitterDaily,"DataJitterDaily",DataJitterDaily,"Jitter","ms","#42ecf5");
	Draw_Chart("LineChartDriftDaily",LineChartDriftDaily,"DataDriftDaily",DataDriftDaily,"Drift","ppm","#ffffff");
}

function initial(){
	show_menu();
	RedrawAllCharts();
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
<input type="button" onClick="RedrawAllCharts();" value="Reset Zoom" class="button_gen" name="button">
</td>
</tr>
<thead>
<tr>
<td colspan="2">Last 24 Hours</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartOffsetDaily" height="300"></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartJitterDaily" height="300"></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartDriftDaily" height="300"></div>
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
