<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>NTP Daemon</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p {
  font-weight: bolder;
}
.collapsible {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}
.collapsible-jquery {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}
.collapsiblecontent {
  padding: 0px;
  max-height: 0;
  overflow: hidden;
  border: none;
  transition: max-height 0.2s ease-out;
}
.invalid {
  background-color: darkred !important;
}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-annotation.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/d3.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/ntpmerlin/ntpstatstext.js"></script>
<script>
var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)

var ShowLines=GetCookie("ShowLines");
var ShowFill=GetCookie("ShowFill");
Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates) {
	return coordinates;
};

var metriclist = ["Offset","Sys_Jitter","Frequency"];
var titlelist = ["Offset","Jitter","Drift"];
var measureunitlist = ["ms","ms","ppm"];
var chartlist = ["daily","weekly","monthly"];
var timeunitlist = ["hour","day","day"];
var intervallist = [24,7,30];
var colourlist = ["#fc8500","#42ecf5","#ffffff"];

function keyHandler(e) {
	if (e.keyCode == 27){
		$j(document).off("keydown");
		ResetZoom();
	}
}

$j(document).keydown(function(e){keyHandler(e);});
$j(document).keyup(function(e){
	$j(document).keydown(function(e){
		keyHandler(e);
	});
});


function Draw_Chart_NoData(txtchartname){
	document.getElementById("divLineChart"+txtchartname).width="730";
	document.getElementById("divLineChart"+txtchartname).height="300";
	document.getElementById("divLineChart"+txtchartname).style.width="730px";
	document.getElementById("divLineChart"+txtchartname).style.height="300px";
	var ctx = document.getElementById("divLineChart"+txtchartname).getContext("2d");
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = "normal normal bolder 48px Arial";
	ctx.fillStyle = 'white';
	ctx.fillText('No data to display', 365, 150);
	ctx.restore();
}

function Draw_Chart(txtchartname,txttitle,txtunity,txtunitx,numunitx,colourname){
	if(typeof dataobject === 'undefined' || dataobject === null) { Draw_Chart_NoData(txtchartname); return; }
	if (dataobject.length == 0) { Draw_Chart_NoData(txtchartname); return; }
	
	var chartLabels = dataobject.map(function(d) {return d.Metric});
	var chartData = dataobject.map(function(d) {return {x: d.Time, y: d.Value}});
	var objchartname=window["LineChart"+txtchartname];
	
	factor=0;
	if (txtunitx=="hour"){
		factor=60*60*1000;
	}
	else if (txtunitx=="day"){
		factor=60*60*24*1000;
	}
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("divLineChart"+txtchartname).getContext("2d");
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		hover: { mode: "point" },
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: true, text: txttitle },
		tooltips: {
			callbacks: {
					title: function (tooltipItem, data) { return (moment(tooltipItem[0].xLabel,"X").format('YYYY-MM-DD HH:mm:ss')); },
					label: function (tooltipItem, data) { return round(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y,3).toFixed(3) + ' ' + txtunity;}
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
					min: moment().subtract(numunitx, txtunitx+"s"),
					display: true
				},
				time: { parser: "X", unit: txtunitx, stepSize: 1 }
			}],
			yAxes: [{
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: txttitle },
				ticks: {
					display: true,
					callback: function (value, index, values) {
						return round(value,3).toFixed(3) + ' ' + txtunity;
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
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(chartData,"y","min",false) - Math.sqrt(Math.pow(getLimit(chartData,"y","min",false),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(chartData,"y","max",false) + getLimit(chartData,"y","max",false)*0.1,
					},
				},
				zoom: {
					enabled: true,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(chartData,"y","min",false) - Math.sqrt(Math.pow(getLimit(chartData,"y","min",false),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(chartData,"y","max",false) + getLimit(chartData,"y","max",false)*0.1,
					},
					speed: 0.1
				},
			},
		},
		annotation: {
			drawTime: 'afterDatasetsDraw',
			annotations: [{
				//id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getAverage(chartData),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Avg=" + round(getAverage(chartData),3).toFixed(3)+txtunity,
				}
			},
			{
				//id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getLimit(chartData,"y","max",true),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Max=" + round(getLimit(chartData,"y","max",true),3).toFixed(3)+txtunity,
				}
			},
			{
				//id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getLimit(chartData,"y","min",true),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Min=" + round(getLimit(chartData,"y","min",true),3).toFixed(3)+txtunity,
				}
			}]
		}
	};
	var lineDataset = {
		labels: chartLabels,
		datasets: [{data: chartData,
			borderWidth: 1,
			pointRadius: 1,
			lineTension: 0,
			fill: ShowFill,
			backgroundColor: colourname,
			borderColor: colourname,
		}]
	};
	objchartname = new Chart(ctx, {
		type: 'line',
		data: lineDataset,
		options: lineOptions
	});
	window["LineChart"+txtchartname]=objchartname;
}

function getLimit(datasetname,axis,maxmin,isannotation) {
	var limit=0;
	var values;
	if(axis == "x"){
		values = datasetname.map(function(o) { return o.x } );
	}
	else{
		values = datasetname.map(function(o) { return o.y } );
	}
	
	if(maxmin == "max"){
		limit=Math.max.apply(Math, values);
	}
	else{
		limit=Math.min.apply(Math, values);
	}
	if(maxmin == "max" && limit == 0 && isannotation == false){
		limit = 1;
	}
	return limit;
}

function getAverage(datasetname) {
	var total = 0;
	for(var i = 0; i < datasetname.length; i++) {
		total += (datasetname[i].y*1);
	}
	var avg = total / datasetname.length;
	return avg;
}

function round(value, decimals) {
	return Number(Math.round(value+'e'+decimals)+'e-'+decimals);
}

function ToggleLines() {
	if(ShowLines == ""){
		ShowLines = "line";
		SetCookie("ShowLines","line");
	}
	else {
		ShowLines = "";
		SetCookie("ShowLines","");
	}
	for(i = 0; i < metriclist.length; i++){
		for (i2 = 0; i2 < chartlist.length; i2++) {
			for (i3 = 0; i3 < 3; i3++) {
				window["LineChart"+metriclist[i]+chartlist[i2]].options.annotation.annotations[i3].type=ShowLines;
			}
			window["LineChart"+metriclist[i]+chartlist[i2]].update();
		}
	}
}

function ToggleFill() {
	if(ShowFill == "false"){
		ShowFill = "origin";
		SetCookie("ShowFill","origin");
	}
	else {
		ShowFill = "false";
		SetCookie("ShowFill","false");
	}
	for(i = 0; i < metriclist.length; i++){
		for (i2 = 0; i2 < chartlist.length; i2++) {
			window["LineChart"+metriclist[i]+chartlist[i2]].data.datasets[0].fill=ShowFill;
			window["LineChart"+metriclist[i]+chartlist[i2]].update();
		}
	}
}

function RedrawAllCharts() {
	var i;
	for(i = 0; i < metriclist.length; i++){
		for (i2 = 0; i2 < chartlist.length; i2++) {
			d3.csv('/ext/ntpmerlin/csv/'+metriclist[i]+chartlist[i2]+'.htm').then(Draw_Chart.bind(null,metriclist[i]+chartlist[i2],titlelist[i],measureunitlist[i],timeunitlist[i2],intervallist[i2],colourlist[i]));
		}
	}
	ResetZoom();
}

function GetCookie(cookiename) {
	var s;
	if ((s = cookie.get("ntp_"+cookiename)) != null) {
		return cookie.get("ntp_"+cookiename);
	}
	else {
		return "";
	}
}

function SetCookie(cookiename,cookievalue) {
	cookie.set("ntp_"+cookiename, cookievalue, 31);
}

function AddEventHandlers(){
	var coll = document.getElementsByClassName("collapsible");
	var i;
	
	for (i = 0; i < coll.length; i++) {
		coll[i].addEventListener("click", function() {
			this.classList.toggle("active");
			var content = this.nextElementSibling.firstElementChild.firstElementChild.firstElementChild;
			if (content.style.maxHeight){
				content.style.maxHeight = null;
				SetCookie(this.id,"collapsed");
			} else {
				content.style.maxHeight = content.scrollHeight + "px";
				SetCookie(this.id,"expanded");
			}
		});
		if(GetCookie(coll[i].id) == "expanded"){
			coll[i].click();
		}
	}
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	show_menu();
	RedrawAllCharts();
	AddEventHandlers();
	SetNTPDStatsTitle();
}

function reload() {
	location.reload(true);
}

function ResetZoom(){
	for(i = 0; i < metriclist.length; i++){
		for (i2 = 0; i2 < chartlist.length; i2++) {
			var chartobj = window["LineChart"+metriclist[i]+chartlist[i2]];
			if(typeof chartobj === 'undefined' || chartobj === null) { continue; }
			chartobj.resetZoom();
		}
	}
}

function DragZoom(button){
	var drag = true;
	var pan = false;
	var buttonvalue = "";
	if(button.value.indexOf("On") != -1){
		drag = false;
		pan = true;
		buttonvalue = "Drag Zoom Off";
	}
	else {
		drag = true;
		pan = false;
		buttonvalue = "Drag Zoom On";
	}
	
	if(interfacelist != ""){
		var interfacetextarray = interfacelist.split(',');
		for(i = 0; i < metriclist.length; i++){
			for (i2 = 0; i2 < chartlist.length; i2++) {
				var chartobj = window["LineChart"+metriclist[i]+chartlist[i2]];
				if(typeof chartobj === 'undefined' || chartobj === null) { continue; }
				chartobj.options.plugins.zoom.zoom.drag = drag;
				chartobj.options.plugins.zoom.pan.enabled = pan;
				button.value = buttonvalue;
				chartobj.update();
			}
		}
	}
}

function ExportCSV() {
	location.href = "ext/ntpmerlin/csv/ntpmerlindata.zip";
	return 0;
}

function applyRule() {
	var action_script_tmp = "start_ntpmerlin";
	document.form.action_script.value = action_script_tmp;
	var restart_time = document.form.action_wait.value*1;
	showLoading();
	document.form.submit();
}
</script>
</head>
<body onload="initial();" onunload="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="start_ntpmerlin">
<input type="hidden" name="action_wait" value="30">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
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
<div class="formfonttitle" id="statstitle">NTPD Performance Stats</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<tr class="apply_gen" valign="top" height="35px">
<td style="background-color:rgb(77, 89, 93);border:0px;">
<input type="button" onclick="DragZoom(this);" value="Drag Zoom On" class="button_gen" name="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ResetZoom();" value="Reset Zoom" class="button_gen" name="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleLines();" value="Toggle Lines" class="button_gen" name="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleFill();" value="Toggle Fill" class="button_gen" name="button">
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons2">
<tr class="apply_gen" valign="top" height="35px">
<td style="background-color:rgb(77, 89, 93);border:0px;">
<input type="button" onclick="applyRule();" value="Update stats" class="button_gen" name="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ExportCSV();" value="Export to CSV" class="button_gen" name="button">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible" id="last24">
<tr>
<td colspan="2">Last 24 Hours (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div class="collapsiblecontent">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartOffsetdaily" height="300" /></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartSys_Jitterdaily" height="300" /></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartFrequencydaily" height="300" /></div>
</div>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible" id="last7">
<tr>
<td colspan="2">Last 7 days (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div class="collapsiblecontent">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartOffsetweekly" height="300" /></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartSys_Jitterweekly" height="300" /></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartFrequencyweekly" height="300" /></div>
</div>
</td>
</tr>
</table><div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible" id="last30">
<tr>
<td colspan="2">Last 30 days (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div class="collapsiblecontent">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartOffsetmonthly" height="300" /></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartSys_Jittermonthly" height="300" /></div>
<div style="line-height:10px;">&nbsp;</div>
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="divLineChartFrequencymonthly" height="300" /></div>
</div>
</td>
</tr>
</table>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</form>
<div id="footer">
</div>
</body>
</html>
