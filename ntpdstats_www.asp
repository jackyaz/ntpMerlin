<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>ntpMerlin</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p {
  font-weight: bolder;
}

thead.collapsible-jquery {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

label.settingvalue {
  margin-right: 10px !important;
  vertical-align: top !important;
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
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/ntpmerlin/ntpstatstext.js"></script>
<script>
var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings){
		if (Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if(prop.indexOf("ntpmerlin") != -1 && prop.indexOf("ntpmerlin_version") == -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}

var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)

var maxNoCharts = 9;
var currentNoCharts = 0;

var ShowLines=GetCookie("ShowLines","string");
var ShowFill=GetCookie("ShowFill","string");

var DragZoom = true;
var ChartPan = false;

Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates){
	return coordinates;
};

var metriclist = ["Offset","SysJitter","Frequency"];
var titlelist = ["Offset","Jitter","Drift"];
var measureunitlist = ["ms","ms","ppm"];
var chartlist = ["daily","weekly","monthly"];
var timeunitlist = ["hour","day","day"];
var intervallist = [24,7,30];
var bordercolourlist = ["#fc8500","#42ecf5","#ffffff"];
var backgroundcolourlist = ["rgba(252,133,0,0.5)","rgba(66,236,245,0.5)","rgba(255,255,255,0.5)"];

function keyHandler(e){
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
	document.getElementById("divLineChart_"+txtchartname).width="730";
	document.getElementById("divLineChart_"+txtchartname).height="500";
	document.getElementById("divLineChart_"+txtchartname).style.width="730px";
	document.getElementById("divLineChart_"+txtchartname).style.height="500px";
	var ctx = document.getElementById("divLineChart_"+txtchartname).getContext("2d");
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = "normal normal bolder 48px Arial";
	ctx.fillStyle = 'white';
	ctx.fillText('No data to display', 365, 250);
	ctx.restore();
}

function Draw_Chart(txtchartname,txttitle,txtunity,bordercolourname,backgroundcolourname){
	var chartperiod = getChartPeriod($j("#" + txtchartname + "_Period option:selected").val());
	var txtunitx = timeunitlist[$j("#" + txtchartname + "_Period option:selected").val()];
	var numunitx = intervallist[$j("#" + txtchartname + "_Period option:selected").val()];
	var dataobject = window[txtchartname+chartperiod];
	
	if(typeof dataobject === 'undefined' || dataobject === null){ Draw_Chart_NoData(txtchartname); return; }
	if (dataobject.length == 0){ Draw_Chart_NoData(txtchartname); return; }
	
	var chartLabels = dataobject.map(function(d){return d.Metric});
	var chartData = dataobject.map(function(d){return {x: d.Time, y: d.Value}});
	var objchartname=window["LineChart_"+txtchartname];
	
	var timeaxisformat = getTimeFormat($j("#Time_Format option:selected").val(),"axis");
	var timetooltipformat = getTimeFormat($j("#Time_Format option:selected").val(),"tooltip");
	
	factor=0;
	if (txtunitx=="hour"){
		factor=60*60*1000;
	}
	else if (txtunitx=="day"){
		factor=60*60*24*1000;
	}
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("divLineChart_"+txtchartname).getContext("2d");
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
					title: function (tooltipItem, data){ return (moment(tooltipItem[0].xLabel,"X").format(timetooltipformat)); },
					label: function (tooltipItem, data){ return round(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y,3).toFixed(3) + ' ' + txtunity;}
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
				time: {
					parser: "X",
					unit: txtunitx,
					stepSize: 1,
					displayFormats: timeaxisformat
				}
			}],
			yAxes: [{
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: txttitle },
				ticks: {
					display: true,
					callback: function (value, index, values){
						return round(value,3).toFixed(3) + ' ' + txtunity;
					}
				},
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: ChartPan,
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
					drag: DragZoom,
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
			}
		},
		annotation: {
			drawTime: 'afterDatasetsDraw',
			annotations: [{
				//id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getAverage(chartData),
				borderColor: bordercolourname,
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
				borderColor: bordercolourname,
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
					position: "right",
					enabled: true,
					xAdjust: 15,
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
				borderColor: bordercolourname,
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
					position: "left",
					enabled: true,
					xAdjust: 15,
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
			backgroundColor: backgroundcolourname,
			borderColor: bordercolourname,
		}]
	};
	objchartname = new Chart(ctx, {
		type: 'line',
		data: lineDataset,
		options: lineOptions
	});
	window["LineChart_"+txtchartname]=objchartname;
}

function getLimit(datasetname,axis,maxmin,isannotation){
	var limit=0;
	var values;
	if(axis == "x"){
		values = datasetname.map(function(o){ return o.x } );
	}
	else{
		values = datasetname.map(function(o){ return o.y } );
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

function getAverage(datasetname){
	var total = 0;
	for(var i = 0; i < datasetname.length; i++){
		total += (datasetname[i].y*1);
	}
	var avg = total / datasetname.length;
	return avg;
}

function round(value, decimals){
	return Number(Math.round(value+'e'+decimals)+'e-'+decimals);
}

function ToggleLines(){
	if(ShowLines == ""){
		ShowLines = "line";
		SetCookie("ShowLines","line");
	}
	else{
		ShowLines = "";
		SetCookie("ShowLines","");
	}
	for(i = 0; i < metriclist.length; i++){
		for (i3 = 0; i3 < 3; i3++){
			window["LineChart_"+metriclist[i]].options.annotation.annotations[i3].type=ShowLines;
		}
		window["LineChart_"+metriclist[i]].update();
	}
}

function ToggleFill(){
	if(ShowFill == "false"){
		ShowFill = "origin";
		SetCookie("ShowFill","origin");
	}
	else{
		ShowFill = "false";
		SetCookie("ShowFill","false");
	}
	for(i = 0; i < metriclist.length; i++){
		window["LineChart_"+metriclist[i]].data.datasets[0].fill=ShowFill;
		window["LineChart_"+metriclist[i]].update();
	}
}

function RedrawAllCharts(){
	for(i = 0; i < metriclist.length; i++){
		for (i2 = 0; i2 < chartlist.length; i2++){
			d3.csv('/ext/ntpmerlin/csv/'+metriclist[i].replace("SysJitter","Sys_Jitter")+chartlist[i2]+'.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]));
		}
	}
}

function SetGlobalDataset(txtchartname,dataobject){
	window[txtchartname] = dataobject;
	currentNoCharts++;
	if(currentNoCharts == maxNoCharts){
		document.getElementById("ntpupdate_text").innerHTML = "";
		showhide("imgNTPUpdate", false);
		showhide("ntpupdate_text", false);
		showhide("btnUpdateStats", true);
		for(i = 0; i < metriclist.length; i++){
			console.log(i)
			$j("#"+metriclist[i]+"_Period").val(GetCookie(metriclist[i]+"_Period","number"));
			Draw_Chart(metriclist[i],titlelist[i],measureunitlist[i],bordercolourlist[i],backgroundcolourlist[i]);
		}
	}
}

function getTimeFormat(value,format){
	var timeformat;
	
	if(format == "axis"){
		if (value == 0){
			timeformat = {
				millisecond: 'HH:mm:ss.SSS',
				second: 'HH:mm:ss',
				minute: 'HH:mm',
				hour: 'HH:mm'
			}
		}
		else if (value == 1){
			timeformat = {
				millisecond: 'h:mm:ss.SSS A',
				second: 'h:mm:ss A',
				minute: 'h:mm A',
				hour: 'h A'
			}
		}
	}
	else if(format == "tooltip"){
		if (value == 0){
			timeformat = "YYYY-MM-DD HH:mm:ss";
		}
		else if (value == 1){
			timeformat = "YYYY-MM-DD h:mm:ss A";
		}
	}
	
	return timeformat;
}

function GetCookie(cookiename,returntype){
	var s;
	if ((s = cookie.get("ntp_"+cookiename)) != null){
		return cookie.get("ntp_"+cookiename);
	}
	else{
		if(returntype == "string"){
			return "";
		}
		else if(returntype == "number"){
			return 0;
		}
	}
}

function SetCookie(cookiename,cookievalue){
	cookie.set("ntp_"+cookiename, cookievalue, 31);
}

function AddEventHandlers(){
	$j(".collapsible-jquery").click(function(){
		$j(this).siblings().toggle("fast",function(){
			if($j(this).css("display") == "none"){
				SetCookie($j(this).siblings()[0].id,"collapsed");
			}
			else{
				SetCookie($j(this).siblings()[0].id,"expanded");
			}
		})
	});
	
	$j(".collapsible-jquery").each(function(index,element){
		if(GetCookie($j(this)[0].id,"string") == "collapsed"){
			$j(this).siblings().toggle(false);
		}
		else{
			$j(this).siblings().toggle(true);
		}
	});
}

$j.fn.serializeObject = function(){
	var o = custom_settings;
	var a = this.serializeArray();
	$j.each(a, function(){
		if (o[this.name] !== undefined && this.name.indexOf("ntpmerlin") != -1 && this.name.indexOf("version") == -1){
			if (!o[this.name].push){
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
		} else if (this.name.indexOf("ntpmerlin") != -1 && this.name.indexOf("version") == -1){
			o[this.name] = this.value || '';
		}
	});
	return o;
};

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	LoadCustomSettings();
	show_menu();
	get_conf_file();
	$j("#Time_Format").val(GetCookie("Time_Format","number"));
	ScriptUpdateLayout();
	SetNTPDStatsTitle();
	RedrawAllCharts();
	AddEventHandlers();
}

function ScriptUpdateLayout(){
	var localver = GetVersionNumber("local");
	var serverver = GetVersionNumber("server");
	$j("#scripttitle").text($j("#scripttitle").text()+" - "+localver);
	$j("#ntpmerlin_version_local").text(localver);
	
	if (localver != serverver && serverver != "N/A"){
		$j("#ntpmerlin_version_server").text("Updated version available: "+serverver);
		showhide("btnChkUpdate", false);
		showhide("ntpmerlin_version_server", true);
		showhide("btnDoUpdate", true);
	}
}

function reload(){
	location.reload(true);
}

function getChartPeriod(period){
	var chartperiod = "daily";
	if (period == 0) chartperiod = "daily";
	else if (period == 1) chartperiod = "weekly";
	else if (period == 2) chartperiod = "monthly";
	return chartperiod;
}

function ResetZoom(){
	for(i = 0; i < metriclist.length; i++){
		var chartobj = window["LineChart_"+metriclist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ continue; }
		chartobj.resetZoom();
	}
}

function ToggleDragZoom(button){
	var drag = true;
	var pan = false;
	var buttonvalue = "";
	if(button.value.indexOf("On") != -1){
		drag = false;
		pan = true;
		DragZoom = false;
		ChartPan = true;
		buttonvalue = "Drag Zoom Off";
	}
	else{
		drag = true;
		pan = false;
		DragZoom = true;
		ChartPan = false;
		buttonvalue = "Drag Zoom On";
	}
	
	for(i = 0; i < metriclist.length; i++){
		var chartobj = window["LineChart_"+metriclist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ continue; }
		chartobj.options.plugins.zoom.zoom.drag = drag;
		chartobj.options.plugins.zoom.pan.enabled = pan;
		button.value = buttonvalue;
		chartobj.update();
	}
}

function ExportCSV(){
	location.href = "/ext/ntpmerlin/csv/ntpmerlindata.zip";
	return 0;
}

function update_status(){
	$j.ajax({
		url: '/ext/ntpmerlin/detect_update.js',
		dataType: 'script',
		timeout: 3000,
		error:	function(xhr){
			setTimeout(update_status, 1000);
		},
		success: function(){
			if (updatestatus == "InProgress"){
				setTimeout(update_status, 1000);
			}
			else{
				document.getElementById("imgChkUpdate").style.display = "none";
				showhide("ntpmerlin_version_server", true);
				if(updatestatus != "None"){
					$j("#ntpmerlin_version_server").text("Updated version available: "+updatestatus);
					showhide("btnChkUpdate", false);
					showhide("btnDoUpdate", true);
				}
				else{
					$j("#ntpmerlin_version_server").text("No update available");
					showhide("btnChkUpdate", true);
					showhide("btnDoUpdate", false);
				}
			}
		}
	});
}

function CheckUpdate(){
	showhide("btnChkUpdate", false);
	document.formScriptActions.action_script.value="start_ntpmerlincheckupdate"
	document.formScriptActions.submit();
	document.getElementById("imgChkUpdate").style.display = "";
	setTimeout(update_status, 2000);
}

function DoUpdate(){
	var action_script_tmp = "start_ntpmerlindoupdate";
	document.form.action_script.value = action_script_tmp;
	var restart_time = 10;
	document.form.action_wait.value = restart_time;
	showLoading();
	document.form.submit();
}

function update_ntpstats(){
	$j.ajax({
		url: '/ext/ntpmerlin/detect_ntpmerlin.js',
		dataType: 'script',
		timeout: 1000,
		error: function(xhr){
			setTimeout(update_ntpstats, 1000);
		},
		success: function(){
			if (ntpstatus == "InProgress"){
				setTimeout(update_ntpstats, 1000);
			}
			else if (ntpstatus == "Done"){
				document.getElementById("ntpupdate_text").innerHTML = "Refreshing charts...";
				PostNTPUpdate();
			}
		}
	});
}

function PostNTPUpdate(){
	currentNoCharts = 0;
	reload_js('/ext/ntpmerlin/ntpstatstext.js');
	$j("#Time_Format").val(GetCookie("Time_Format","number"));
	SetNTPDStatsTitle();
	setTimeout(RedrawAllCharts, 3000);
}

function reload_js(src){
	$j('script[src="' + src + '"]').remove();
	$j('<script>').attr('src', src+'?cachebuster='+ new Date().getTime()).appendTo('head');
}

function UpdateStats(){
	showhide("btnUpdateStats", false);
	document.formScriptActions.action_script.value="start_ntpmerlin";
	document.formScriptActions.submit();
	document.getElementById("ntpupdate_text").innerHTML = "Retrieving timeserver stats";
	showhide("imgNTPUpdate", true);
	showhide("ntpupdate_text", true);
	setTimeout(update_ntpstats, 2000);
}

function SaveConfig(){
	document.getElementById('amng_custom').value = JSON.stringify($j('form').serializeObject())
	var action_script_tmp = "start_ntpmerlinconfig";
	document.form.action_script.value = action_script_tmp;
	var restart_time = 10;
	document.form.action_wait.value = restart_time;
	showLoading();
	document.form.submit();
}

function GetVersionNumber(versiontype){
	var versionprop;
	if(versiontype == "local"){
		versionprop = custom_settings.ntpmerlin_version_local;
	}
	else if(versiontype == "server"){
		versionprop = custom_settings.ntpmerlin_version_server;
	}
	
	if(typeof versionprop == 'undefined' || versionprop == null){
		return "N/A";
	}
	else{
		return versionprop;
	}
}

function get_conf_file(){
	$j.ajax({
		url: '/ext/ntpmerlin/config.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_conf_file, 1000);
		},
		success: function(data){
			var configdata=data.split("\n");
			configdata = configdata.filter(Boolean);
			
			for (var i = 0; i < configdata.length; i++){
				eval("document.form.ntpmerlin_"+configdata[i].split("=")[0].toLowerCase()).value = configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,"");
			}
		}
	});
}

function changeChart(e){
	value = e.value * 1;
	name = e.id.substring(0, e.id.indexOf("_"));
	SetCookie(e.id,value);
	
	if(name == "Offset"){
		Draw_Chart("Offset",titlelist[0],measureunitlist[0],bordercolourlist[0],backgroundcolourlist[0]);
	}
	else if(name == "SysJitter"){
		Draw_Chart("SysJitter",titlelist[1],measureunitlist[1],bordercolourlist[1],backgroundcolourlist[1]);
	}
	else if(name == "Frequency"){
		Draw_Chart("Frequency",titlelist[2],measureunitlist[2],bordercolourlist[2],backgroundcolourlist[2]);
	}
}

function changeAllCharts(e){
	value = e.value * 1;
	name = e.id.substring(0, e.id.indexOf("_"));
	SetCookie(e.id,value);
	for (i = 0; i < metriclist.length; i++){
		Draw_Chart(metriclist[i],titlelist[i],measureunitlist[i],bordercolourlist[i],backgroundcolourlist[i]);
	}
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
<input type="hidden" name="action_wait" value="35">
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
<div class="formfonttitle" id="scripttitle" style="text-align:center;">ntpMerlin</div>
<div id="statstitle" style="text-align:center;">Stats last updated:</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">ntpMerlin implements an NTP time server for AsusWRT Merlin with charts for daily, weekly and monthly summaries of performance. A choice between ntpd and chrony is available.</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<thead class="collapsible-jquery" id="scripttools">
<tr><td colspan="2">Utilities (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Version information</th>
<td>
<span id="ntpmerlin_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="ntpmerlin_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<img id="imgChkUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
<tr>
<th width="20%">Update stats</th>
<td>
<input type="button" onclick="UpdateStats();" value="Update stats" class="button_gen" name="btnUpdateStats" id="btnUpdateStats">
<img id="imgNTPUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
&nbsp;&nbsp;&nbsp;
<span id="ntpupdate_text" style="display:none;"></span>
</td>
</tr>
<tr>
<th width="20%">Export</th>
<td>
<input type="button" onclick="ExportCSV();" value="Export to CSV" class="button_gen" name="btnExport">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery" id="scriptconfig">
<tr><td colspan="2">Configuration (click to expand/collapse)</td></tr>
</thead>
<tr class="even" id="rowdataoutput">
<th width="40%">Data Output Mode<br/><span style="color:#FFCC00;">(for weekly and monthly charts)</span></th>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_outputdatamode" id="ntpmerlin_dataoutput_average" class="input" value="average" checked>
<label for="ntpmerlin_dataoutput_average" class="settingvalue">Average</label>
<input type="radio" name="ntpmerlin_outputdatamode" id="ntpmerlin_dataoutput_raw" class="input" value="raw">
<label for="ntpmerlin_dataoutput_raw" class="settingvalue">Raw</label>
</td>
</tr>
<tr class="even" id="rowtimeoutput">
<th width="40%">Time Output Mode<br/><span style="color:#FFCC00;">(for CSV export)</span></th>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_outputtimemode" id="ntpmerlin_timeoutput_non-unix" class="input" value="non-unix" checked>
<label for="ntpmerlin_timeoutput_non-unix" class="settingvalue">Non-Unix</label>
<input type="radio" name="ntpmerlin_outputtimemode" id="ntpmerlin_timeoutput_unix" class="input" value="unix">
<label for="ntpmerlin_timeoutput_unix" class="settingvalue">Unix</label>
</td>
</tr>
<tr class="even" id="rowstorageloc">
<th width="40%">Data Storage Location</th>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_storagelocation" id="ntpmerlin_storageloc_jffs" class="input" value="jffs" checked>
<label for="ntpmerlin_storageloc_jffs" class="settingvalue">JFFS</label>
<input type="radio" name="ntpmerlin_storagelocation" id="ntpmerlin_storageloc_usb" class="input" value="usb">
<label for="ntpmerlin_storageloc_usb" class="settingvalue">USB</label>
</td>
</tr>
<tr class="even" id="rowtimeserver">
<th width="40%">Timeserver</th>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_timeserver" id="ntpmerlin_timeserver_ntpd" class="input" value="ntpd" checked>
<label for="ntpmerlin_timeserver_ntpd" class="settingvalue">NTPD</label>
<input type="radio" name="ntpmerlin_timeserver" id="ntpmerlin_timeserver_chronyd" class="input" value="chronyd">
<label for="ntpmerlin_timeserver_chronyd" class="settingvalue">Chrony</label>
</td>
</tr>
<tr class="apply_gen" valign="top" height="35px">
<td colspan="2" style="background-color:rgb(77, 89, 93);">
<input type="button" onclick="SaveConfig();" value="Save" class="button_gen" name="button">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons2">
<thead class="collapsible-jquery" id="ntpmerlin_charttools">
<tr><td colspan="2">Chart Display Options (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%"><span style="color:#FFFFFF;">Time format</span><br /><span style="color:#FFCC00;">(for tooltips and Last 24h chart axis)</span></th>
<td>
<select style="width:100px" class="input_option" onchange="changeAllCharts(this)" id="Time_Format">
<option value="0">24h</option>
<option value="1">12h</option>
</select>
</td>
</tr>
<tr class="apply_gen" valign="top">
<td style="background-color:rgb(77, 89, 93);" colspan="2">
<input type="button" onclick="ToggleDragZoom(this);" value="Drag Zoom On" class="button_gen" name="btnDragZoom">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ResetZoom();" value="Reset Zoom" class="button_gen" name="btnResetZoom">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleLines();" value="Toggle Lines" class="button_gen" name="btnToggleLines">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleFill();" value="Toggle Fill" class="button_gen" name="btnToggleFill">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="table_charts">
<thead class="collapsible-jquery" id="thead_charts">
<tr>
<td>Charts (click to expand/collapse)</td>
</tr>
</thead>
<tr><td align="center" style="padding: 0px;">
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="chart_offset">
<tr>
<td colspan="2">Offset (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Period to display</th>
<td>
<select style="width:125px" class="input_option" onchange="changeChart(this)" id="Offset_Period">
<option value="0">Last 24 hours</option>
<option value="1">Last 7 days</option>
<option value="2">Last 30 days</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divLineChart_Offset" height="500" /></div>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="chart_sysjitter">
<tr>
<td colspan="2">Jitter (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Period to display</th>
<td>
<select style="width:125px" class="input_option" onchange="changeChart(this)" id="SysJitter_Period">
<option value="0">Last 24 hours</option>
<option value="1">Last 7 days</option>
<option value="2">Last 30 days</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divLineChart_SysJitter" height="500" /></div>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="chart_frequency">
<tr>
<td colspan="2">Drift (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Period to display</th>
<td>
<select style="width:125px" class="input_option" onchange="changeChart(this)" id="Frequency_Period">
<option value="0">Last 24 hours</option>
<option value="1">Last 7 days</option>
<option value="2">Last 30 days</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divLineChart_Frequency" height="500" /></div>
</td>
</tr>
</table>
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
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
</form>
<div id="footer"></div>
</body>
</html>
