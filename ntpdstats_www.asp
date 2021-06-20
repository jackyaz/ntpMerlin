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
p{font-weight:bolder}thead.collapsible-jquery{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}td.nodata{height:65px!important;border:none!important;text-align:center!important;font:bolder 48px Arial!important}.SettingsTable{text-align:left}.SettingsTable input{text-align:left;margin-left:3px!important}.SettingsTable input.savebutton{text-align:center;margin-top:5px;margin-bottom:5px;border-right:solid 1px #000;border-left:solid 1px #000;border-bottom:solid 1px #000}.SettingsTable td.savebutton{border-right:solid 1px #000;border-left:solid 1px #000;border-bottom:solid 1px #000;background-color:#4d595d}.SettingsTable .cronbutton{text-align:center;min-width:50px;width:50px;height:23px;vertical-align:middle}.SettingsTable select{margin-left:3px!important}.SettingsTable label{margin-right:10px!important;vertical-align:top!important}.SettingsTable th{background-color:#1F2D35!important;background:#2F3A3E!important;border-bottom:none!important;border-top:none!important;font-size:12px!important;color:#fff!important;padding:4px!important;font-weight:bolder!important;padding:0!important}.SettingsTable td{word-wrap:break-word!important;overflow-wrap:break-word!important;border-right:none;border-left:none}.SettingsTable span.settingname{background-color:#1F2D35!important;background:#2F3A3E!important}.SettingsTable td.settingname{border-right:solid 1px #000;border-left:solid 1px #000;background-color:#1F2D35!important;background:#2F3A3E!important;width:35%!important}.SettingsTable td.settingvalue{text-align:left!important;border-right:solid 1px #000}.SettingsTable th:first-child{border-left:none!important}.SettingsTable th:last-child{border-right:none!important}.SettingsTable .invalid{background-color:#8b0000!important}.SettingsTable .disabled{background-color:#CCC!important;color:#888!important}.removespacing{padding-left:0!important;margin-left:0!important;margin-bottom:5px!important;text-align:center!important}div.sortTableContainer{height:300px;overflow-y:scroll;width:745px;border:1px solid #000}.sortTable{table-layout:fixed!important;border:none}thead.sortTableHeader th{background-image:linear-gradient(#92a0a5 0%,#66757c 100%);border-top:none!important;border-left:none!important;border-right:none!important;border-bottom:1px solid #000!important;font-weight:bolder;padding:2px;text-align:center;color:#fff;position:sticky;top:0;font-size:11px!important}thead.sortTableHeader th:first-child,thead.sortTableHeader th:last-child{border-right:none!important}thead.sortTableHeader th:first-child,thead.sortTableHeader td:first-child{border-left:none!important}tbody.sortTableContent td{border-bottom:1px solid #000!important;border-left:none!important;border-right:1px solid #000!important;border-top:none!important;padding:2px;text-align:center;overflow:hidden!important;white-space:nowrap!important;font-size:12px!important}tbody.sortTableContent tr.sortRow:nth-child(odd) td{background-color:#2F3A3E!important}tbody.sortTableContent tr.sortRow:nth-child(even) td{background-color:#475A5F!important}th.sortable{cursor:pointer}
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
<script>
var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for(var prop in custom_settings){
		if(Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if(prop.indexOf('ntpmerlin') != -1 && prop.indexOf('ntpmerlin_version') == -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}
var $j=jQuery.noConflict(),arraysortlistlines=[],sortfield="Time",sortname="Time",sortdir="desc",maxNoCharts=18,currentNoCharts=0,ShowLines=GetCookie("ShowLines","string"),ShowFill=GetCookie("ShowFill","string"),DragZoom=!0,ChartPan=!1;Chart.defaults.global.defaultFontColor="#CCC",Chart.Tooltip.positioners.cursor=function(a,b){return b};var dataintervallist=["raw","hour","day"],metriclist=["Offset","Drift"],measureunitlist=["ms","ppm"],chartlist=["daily","weekly","monthly"],timeunitlist=["hour","day","day"],intervallist=[24,7,30],bordercolourlist=["#fc8500","#ffffff"],backgroundcolourlist=["rgba(252,133,0,0.5)","rgba(255,255,255,0.5)"];function keyHandler(a){82==a.keyCode?($j(document).off("keydown"),ResetZoom()):68==a.keyCode?($j(document).off("keydown"),ToggleDragZoom(document.form.btnDragZoom)):70==a.keyCode?($j(document).off("keydown"),ToggleFill()):76==a.keyCode&&($j(document).off("keydown"),ToggleLines())}$j(document).keydown(function(a){keyHandler(a)}),$j(document).keyup(function(){$j(document).keydown(function(a){keyHandler(a)})});function Draw_Chart_NoData(a){document.getElementById("divLineChart_"+a).width="730",document.getElementById("divLineChart_"+a).height="500",document.getElementById("divLineChart_"+a).style.width="730px",document.getElementById("divLineChart_"+a).style.height="500px";var b=document.getElementById("divLineChart_"+a).getContext("2d");b.save(),b.textAlign="center",b.textBaseline="middle",b.font="normal normal bolder 48px Arial",b.fillStyle="white",b.fillText("No data to display",365,250),b.restore()}function Draw_Chart(a,b,c,d,e){var f=getChartPeriod($j("#"+a+"_Period option:selected").val()),g=getChartInterval($j("#"+a+"_Interval option:selected").val()),h=timeunitlist[$j("#"+a+"_Period option:selected").val()],i=intervallist[$j("#"+a+"_Period option:selected").val()],j=moment(),k=null,l=moment().subtract(i,h+"s"),m="line",n=window[a+"_"+g+"_"+f];if("undefined"==typeof n||null===n)return void Draw_Chart_NoData(a);if(0==n.length)return void Draw_Chart_NoData(a);var o=n.map(function(a){return a.Metric}),p=n.map(function(a){return{x:a.Time,y:a.Value}}),q=window["LineChart_"+a],r=getTimeFormat($j("#Time_Format option:selected").val(),"axis"),s=getTimeFormat($j("#Time_Format option:selected").val(),"tooltip");"day"==g&&(m="bar",k=moment().endOf("day").subtract(9,"hours"),l=moment().startOf("day").subtract(i-1,h+"s").subtract(12,"hours"),j=k),"daily"==f&&"day"==g&&(h="day",i=1,k=moment().endOf("day").subtract(9,"hours"),l=moment().startOf("day").subtract(12,"hours"),j=k),factor=0,"hour"==h?factor=3600000:"day"==h&&(factor=86400000),q!=null&&q.destroy();var t=document.getElementById("divLineChart_"+a).getContext("2d"),u={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!1,position:"bottom",onClick:null},title:{display:!0,text:b},tooltips:{callbacks:{title:function(a){return"day"==g?moment(a[0].xLabel,"X").format("YYYY-MM-DD"):moment(a[0].xLabel,"X").format(s)},label:function(a,b){return round(b.datasets[a.datasetIndex].data[a.index].y,3).toFixed(3)+" "+c}},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{type:"time",gridLines:{display:!0,color:"#282828"},ticks:{min:l,max:k,display:!0},time:{parser:"X",unit:h,stepSize:1,displayFormats:r}}],yAxes:[{gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:c},ticks:{display:!0,callback:function(a){return round(a,3).toFixed(3)+" "+c}}}]},plugins:{zoom:{pan:{enabled:ChartPan,mode:"xy",rangeMin:{x:l,y:getLimit(p,"y","min",!1)-.1*Math.sqrt(Math.pow(getLimit(p,"y","min",!1),2))},rangeMax:{x:j,y:getLimit(p,"y","max",!1)+.1*getLimit(p,"y","max",!1)}},zoom:{enabled:!0,drag:DragZoom,mode:"xy",rangeMin:{x:l,y:getLimit(p,"y","min",!1)-.1*Math.sqrt(Math.pow(getLimit(p,"y","min",!1),2))},rangeMax:{x:j,y:getLimit(p,"y","max",!1)+.1*getLimit(p,"y","max",!1)},speed:.1}}},annotation:{drawTime:"afterDatasetsDraw",annotations:[{type:ShowLines,mode:"horizontal",scaleID:"y-axis-0",value:getAverage(p),borderColor:d,borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg="+round(getAverage(p),3).toFixed(3)+c}},{type:ShowLines,mode:"horizontal",scaleID:"y-axis-0",value:getLimit(p,"y","max",!0),borderColor:d,borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max="+round(getLimit(p,"y","max",!0),3).toFixed(3)+c}},{type:ShowLines,mode:"horizontal",scaleID:"y-axis-0",value:getLimit(p,"y","min",!0),borderColor:d,borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min="+round(getLimit(p,"y","min",!0),3).toFixed(3)+c}}]}},v={labels:o,datasets:[{data:p,borderWidth:1,pointRadius:1,lineTension:0,fill:ShowFill,backgroundColor:e,borderColor:d}]};q=new Chart(t,{type:m,data:v,options:u}),window["LineChart_"+a]=q}function getLimit(a,b,c,d){var e,f=0;return e="x"==b?a.map(function(a){return a.x}):a.map(function(a){return a.y}),f="max"==c?Math.max.apply(Math,e):Math.min.apply(Math,e),"max"==c&&0==f&&!1==d&&(f=1),f}function getAverage(a){for(var b=0,c=0;c<a.length;c++)b+=1*a[c].y;var d=b/a.length;return d}function round(a,b){return+(Math.round(a+"e"+b)+"e-"+b)}function ToggleLines(){""==ShowLines?(ShowLines="line",SetCookie("ShowLines","line")):(ShowLines="",SetCookie("ShowLines",""));for(var a=0;a<metriclist.length;a++){for(var b=0;3>b;b++)window["LineChart_"+metriclist[a]].options.annotation.annotations[b].type=ShowLines;window["LineChart_"+metriclist[a]].update()}}function ToggleFill(){"false"==ShowFill?(ShowFill="origin",SetCookie("ShowFill","origin")):(ShowFill="false",SetCookie("ShowFill","false"));for(var a=0;a<metriclist.length;a++)window["LineChart_"+metriclist[a]].data.datasets[0].fill=ShowFill,window["LineChart_"+metriclist[a]].update()}function RedrawAllCharts(){for(var a=0;a<metriclist.length;a++){Draw_Chart_NoData(metriclist[a]);for(var b=0;b<chartlist.length;b++)for(var c=0;c<dataintervallist.length;c++)d3.csv("/ext/ntpmerlin/csv/"+metriclist[a]+"_"+dataintervallist[c]+"_"+chartlist[b]+".htm").then(SetGlobalDataset.bind(null,metriclist[a]+"_"+dataintervallist[c]+"_"+chartlist[b]))}}function SetGlobalDataset(a,b){if(window[a]=b,currentNoCharts++,currentNoCharts==maxNoCharts){document.getElementById("ntpupdate_text").innerHTML="",showhide("imgNTPUpdate",!1),showhide("ntpupdate_text",!1),showhide("btnUpdateStats",!0);for(var c=0;c<metriclist.length;c++)$j("#"+metriclist[c]+"_Interval").val(GetCookie(metriclist[c]+"_Interval","number")),changePeriod(document.getElementById(metriclist[c]+"_Interval")),$j("#"+metriclist[c]+"_Period").val(GetCookie(metriclist[c]+"_Period","number")),Draw_Chart(metriclist[c],metriclist[c],measureunitlist[c],bordercolourlist[c],backgroundcolourlist[c]);AddEventHandlers(),get_lastx_file()}}function getTimeFormat(a,b){var c;return"axis"==b?0==a?c={millisecond:"HH:mm:ss.SSS",second:"HH:mm:ss",minute:"HH:mm",hour:"HH:mm"}:1==a&&(c={millisecond:"h:mm:ss.SSS A",second:"h:mm:ss A",minute:"h:mm A",hour:"h A"}):"tooltip"==b&&(0==a?c="YYYY-MM-DD HH:mm:ss":1==a&&(c="YYYY-MM-DD h:mm:ss A")),c}function GetCookie(a,b){var c;if(null!=(c=cookie.get("ntp_"+a)))return cookie.get("ntp_"+a);return"string"==b?"":"number"==b?0:void 0}function SetCookie(a,b){cookie.set("ntp_"+a,b,3650)}function AddEventHandlers(){$j(".collapsible-jquery").off("click").on("click",function(){$j(this).siblings().toggle("fast",function(){"none"==$j(this).css("display")?SetCookie($j(this).siblings()[0].id,"collapsed"):SetCookie($j(this).siblings()[0].id,"expanded")})}),$j(".collapsible-jquery").each(function(){"collapsed"==GetCookie($j(this)[0].id,"string")?$j(this).siblings().toggle(!1):$j(this).siblings().toggle(!0)})}$j.fn.serializeObject=function(){var b=custom_settings,c=this.serializeArray();return $j.each(c,function(){void 0!==b[this.name]&&-1!=this.name.indexOf("ntpmerlin")&&-1==this.name.indexOf("version")?(!b[this.name].push&&(b[this.name]=[b[this.name]]),b[this.name].push(this.value||"")):-1!=this.name.indexOf("ntpmerlin")&&-1==this.name.indexOf("version")&&(b[this.name]=this.value||"")}),b};function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function ErrorCSVExport(){document.getElementById("aExport").href="javascript:alert('Error exporting CSV,please refresh the page and try again')"}function ParseCSVExport(a){for(var b,c="Timestamp,Offset,Frequency,Sys_Jitter,Clk_Jitter,Clk_Wander,Rootdisp\n",d=0;d<a.length;d++)b=a[d].Timestamp+","+a[d].Offset+","+a[d].Frequency+","+a[d].Sys_Jitter+","+a[d].Clk_Jitter+","+a[d].Clk_Wander+","+a[d].Rootdisp,c+=d<a.length-1?b+"\n":b;document.getElementById("aExport").href="data:text/csv;charset=utf-8,"+encodeURIComponent(c)}function initial(){SetCurrentPage(),LoadCustomSettings(),show_menu(),$j("#sortTableContainer").empty(),$j("#sortTableContainer").append(BuildLastXTableNoData()),get_conf_file(),d3.csv("/ext/ntpmerlin/csv/CompleteResults.htm").then(function(a){ParseCSVExport(a)}).catch(function(){ErrorCSVExport()}),$j("#Time_Format").val(GetCookie("Time_Format","number")),ScriptUpdateLayout(),get_statstitle_file(),RedrawAllCharts()}function ScriptUpdateLayout(){var a=GetVersionNumber("local"),b=GetVersionNumber("server");$j("#ntpmerlin_version_local").text(a),a!=b&&"N/A"!=b&&($j("#ntpmerlin_version_server").text("Updated version available: "+b),showhide("btnChkUpdate",!1),showhide("ntpmerlin_version_server",!0),showhide("btnDoUpdate",!0))}function reload(){location.reload(!0)}function Validate_Number_Setting(a,b,c){var d=a.name,e=1*a.value;return e>b||e<c?($j(a).addClass("invalid"),!1):($j(a).removeClass("invalid"),!0)}function Format_Number_Setting(a){var b=a.name,c=1*a.value;return 0!=a.value.length&&c!=NaN&&(a.value=parseInt(a.value),!0)}function Validate_All(){var a=!1;return Validate_Number_Setting(document.form.ntpmerlin_lastxresults,100,10)||(a=!0),Validate_Number_Setting(document.form.ntpmerlin_daystokeep,365,30)||(a=!0),!a||(alert("Validation for some fields failed. Please correct invalid values and try again."),!1)}function getChartPeriod(a){var b="daily";return 0==a?b="daily":1==a?b="weekly":2==a&&(b="monthly"),b}function getChartInterval(a){var b="raw";return 0==a?b="raw":1==a?b="hour":2==a&&(b="day"),b}function changePeriod(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),2==value?$j("select[id=\""+name+"_Period\"] option:contains(24)").text("Today"):$j("select[id=\""+name+"_Period\"] option:contains(\"Today\")").text("Last 24 hours")}function ResetZoom(){for(var a,b=0;b<metriclist.length;b++)(a=window["LineChart_"+metriclist[b]],"undefined"!=typeof a&&null!==a)&&a.resetZoom()}function ToggleDragZoom(a){var b=!0,c=!1,d="";-1==a.value.indexOf("On")?(b=!0,c=!1,DragZoom=!0,ChartPan=!1,d="Drag Zoom On"):(b=!1,c=!0,DragZoom=!1,ChartPan=!0,d="Drag Zoom Off");for(var e,f=0;f<metriclist.length;f++)(e=window["LineChart_"+metriclist[f]],"undefined"!=typeof e&&null!==e)&&(e.options.plugins.zoom.zoom.drag=b,e.options.plugins.zoom.pan.enabled=c,a.value=d,e.update())}function update_status(){$j.ajax({url:"/ext/ntpmerlin/detect_update.js",dataType:"script",timeout:3e3,error:function(){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("ntpmerlin_version_server",!0),"None"==updatestatus?($j("#ntpmerlin_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)):($j("#ntpmerlin_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_ntpmerlincheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.form.action_script.value="start_ntpmerlindoupdate",document.form.action_wait.value=10,showLoading(),document.form.submit()}function update_ntpstats(){$j.ajax({url:"/ext/ntpmerlin/detect_ntpmerlin.js",dataType:"script",timeout:1e3,error:function(){setTimeout(update_ntpstats,1e3)},success:function(){"InProgress"==ntpstatus?setTimeout(update_ntpstats,1e3):"GenerateCSV"==ntpstatus?(document.getElementById("ntpupdate_text").innerHTML="Retrieving data for charts...",setTimeout(update_ntpstats,1e3)):"Done"==ntpstatus&&(document.getElementById("ntpupdate_text").innerHTML="Refreshing charts...",PostNTPUpdate())}})}function PostNTPUpdate(){currentNoCharts=0,$j("#Time_Format").val(GetCookie("Time_Format","number")),get_statstitle_file(),setTimeout(RedrawAllCharts,3e3)}function UpdateStats(){showhide("btnUpdateStats",!1),document.formScriptActions.action_script.value="start_ntpmerlin",document.formScriptActions.submit(),document.getElementById("ntpupdate_text").innerHTML="Retrieving timeserver stats",showhide("imgNTPUpdate",!0),showhide("ntpupdate_text",!0),setTimeout(update_ntpstats,2e3)}function SaveConfig(){document.getElementById("amng_custom").value=JSON.stringify($j("form").serializeObject()),document.form.action_script.value="start_ntpmerlinconfig",document.form.action_wait.value=10,showLoading(),document.form.submit()}function GetVersionNumber(a){var b;return"local"==a?b=custom_settings.ntpmerlin_version_local:"server"==a&&(b=custom_settings.ntpmerlin_version_server),"undefined"==typeof b||null==b?"N/A":b}function get_conf_file(){$j.ajax({url:"/ext/ntpmerlin/config.htm",dataType:"text",error:function(){setTimeout(get_conf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)eval("document.form.ntpmerlin_"+configdata[i].split("=")[0].toLowerCase()).value=configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,"")}})}function get_statstitle_file(){$j.ajax({url:"/ext/ntpmerlin/ntpstatstext.js",dataType:"script",timeout:3e3,error:function(){setTimeout(get_statstitle_file,1e3)},success:function(){SetNTPDStatsTitle()}})}function get_lastx_file(){$j.ajax({url:"/ext/ntpmerlin/lastx.htm",dataType:"text",timeout:3e3,error:function(){setTimeout(get_lastx_file,1e3)},success:function(a){ParseLastXData(a)}})}function ParseLastXData(a){var b=a.split("\n");b=b.filter(Boolean),arraysortlistlines=[];for(var c=0;c<b.length;c++)try{var d=b[c].split(","),e={};e.Time=moment.unix(d[0].trim()).format("YYYY-MM-DD HH:mm:ss"),e.Offset=d[1].trim(),e.Drift=d[2].trim(),arraysortlistlines.push(e)}catch{}SortTable(sortname+" "+sortdir.replace("desc","\u2191").replace("asc","\u2193").trim())}function SortTable(sorttext){sortname=sorttext.replace("\u2191","").replace("\u2193","").trim();var sorttype="number";sortfield=sortname;"Time"===sortname?sorttype="date":void 0;"string"==sorttype?-1==sorttext.indexOf("\u2193")&&-1==sorttext.indexOf("\u2191")?(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => (a."+sortfield+" > b."+sortfield+") ? 1 : ((b."+sortfield+" > a."+sortfield+") ? -1 : 0));"),sortdir="asc"):-1==sorttext.indexOf("\u2193")?(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => (a."+sortfield+" < b."+sortfield+") ? 1 : ((b."+sortfield+" < a."+sortfield+") ? -1 : 0));"),sortdir="desc"):(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => (a."+sortfield+" > b."+sortfield+") ? 1 : ((b."+sortfield+" > a."+sortfield+") ? -1 : 0));"),sortdir="asc"):"number"==sorttype?-1==sorttext.indexOf("\u2193")&&-1==sorttext.indexOf("\u2191")?(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => parseFloat(a."+sortfield+".replace(\"m\",\"000\")) - parseFloat(b."+sortfield+".replace(\"m\",\"000\")));"),sortdir="asc"):-1==sorttext.indexOf("\u2193")?(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => parseFloat(b."+sortfield+".replace(\"m\",\"000\")) - parseFloat(a."+sortfield+".replace(\"m\",\"000\")));"),sortdir="desc"):(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => parseFloat(a."+sortfield+".replace(\"m\",\"000\")) - parseFloat(b."+sortfield+".replace(\"m\",\"000\"))); "),sortdir="asc"):"date"==sorttype&&(-1==sorttext.indexOf("\u2193")&&-1==sorttext.indexOf("\u2191")?(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => new Date(a."+sortfield+") - new Date(b."+sortfield+"));"),sortdir="asc"):-1==sorttext.indexOf("\u2193")?(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => new Date(b."+sortfield+") - new Date(a."+sortfield+"));"),sortdir="desc"):(eval("arraysortlistlines = arraysortlistlines.sort((a,b) => new Date(a."+sortfield+") - new Date(b."+sortfield+"));"),sortdir="asc")),$j("#sortTableContainer").empty(),$j("#sortTableContainer").append(BuildLastXTable()),$j(".sortable").each(function(a,b){b.innerHTML.replace(/ \(.*\)/,"").replace(" ","")==sortname&&("asc"==sortdir?b.innerHTML+=" \u2191":b.innerHTML+=" \u2193")})}function BuildLastXTableNoData(){var a="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"sortTable\">";return a+="<tr>",a+="<td colspan=\"3\" class=\"nodata\">",a+="Data loading...",a+="</td>",a+="</tr>",a+="</table>",a}function BuildLastXTable(){var a="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"sortTable\">";a+="<col style=\"width:150px;\">",a+="<col style=\"width:280px;\">",a+="<col style=\"width:280px;\">",a+="<thead class=\"sortTableHeader\">",a+="<tr>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML.replace(/ \\(.*\\)/,''))\">Time</th>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML.replace(/ \\(.*\\)/,''))\">Offset (ms)</th>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML.replace(/ \\(.*\\)/,''))\">Drift (ppm)</th>",a+="</tr>",a+="</thead>",a+="<tbody class=\"sortTableContent\">";for(var b=0;b<arraysortlistlines.length;b++)a+="<tr class=\"sortRow\">",a+="<td>"+arraysortlistlines[b].Time+"</td>",a+="<td>"+arraysortlistlines[b].Offset+"</td>",a+="<td>"+arraysortlistlines[b].Drift+"</td>",a+="</tr>";return a+="</tbody>",a+="</table>",a}function changeChart(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),SetCookie(a.id,value),"Offset"==name?Draw_Chart("Offset",metriclist[0],measureunitlist[0],bordercolourlist[0],backgroundcolourlist[0]):"Drift"==name&&Draw_Chart("Drift",metriclist[1],measureunitlist[1],bordercolourlist[1],backgroundcolourlist[1])}function changeAllCharts(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),SetCookie(a.id,value);for(var b=0;b<metriclist.length;b++)Draw_Chart(metriclist[b],metriclist[b],measureunitlist[b],bordercolourlist[b],backgroundcolourlist[b])}
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
<a id="aExport" href="" download="ntpmerlin.csv"><input type="button" value="Export to CSV" class="button_gen" name="btnExport"></a>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable SettingsTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery" id="scriptconfig">
<tr><td colspan="2">Configuration (click to expand/collapse)</td></tr>
</thead>
<tr class="even" id="rowtimeoutput">
<td class="settingname">Time Output Mode<br/><span class="settingname">(for CSV export)</span></td>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_outputtimemode" id="ntpmerlin_timeoutput_non-unix" class="input" value="non-unix" checked>
<label for="ntpmerlin_timeoutput_non-unix">Non-Unix</label>
<input type="radio" name="ntpmerlin_outputtimemode" id="ntpmerlin_timeoutput_unix" class="input" value="unix">
<label for="ntpmerlin_timeoutput_unix">Unix</label>
</td>
</tr>
<tr class="even" id="rowstorageloc">
<td class="settingname">Data Storage Location</td>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_storagelocation" id="ntpmerlin_storageloc_jffs" class="input" value="jffs" checked>
<label for="ntpmerlin_storageloc_jffs">JFFS</label>
<input type="radio" name="ntpmerlin_storagelocation" id="ntpmerlin_storageloc_usb" class="input" value="usb">
<label for="ntpmerlin_storageloc_usb">USB</label>
</td>
</tr>
<tr class="even" id="rowtimeserver">
<td class="settingname">Timeserver</td>
<td class="settingvalue">
<input type="radio" name="ntpmerlin_timeserver" id="ntpmerlin_timeserver_ntpd" class="input" value="ntpd" checked>
<label for="ntpmerlin_timeserver_ntpd">NTPD</label>
<input type="radio" name="ntpmerlin_timeserver" id="ntpmerlin_timeserver_chronyd" class="input" value="chronyd">
<label for="ntpmerlin_timeserver_chronyd">Chrony</label>
</td>
</tr>
<tr class="even" id="rowlastxresults">
<td class="settingname">Last X results to display</td>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="3" class="input_6_table removespacing" name="ntpmerlin_lastxresults" value="10" onkeypress="return validator.isNumber(this,event)" onblur="Validate_Number_Setting(this,100,1);Format_Number_Setting(this)" onkeyup="Validate_Number_Setting(this,100,1)"/>
&nbsp;results <span style="color:#FFCC00;">(between 1 and 100, default: 10)</span>
</td>
</tr>
<tr class="even" id="rowdaystokeep">
<td class="settingname">Number of days of data to keep</td>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="3" class="input_6_table removespacing" name="ntpmerlin_daystokeep" value="30" onkeypress="return validator.isNumber(this,event)" onblur="Validate_Number_Setting(this,365,30);Format_Number_Setting(this)" onkeyup="Validate_Number_Setting(this,365,30)"/>
&nbsp;days <span style="color:#FFCC00;">(between 30 and 365, default: 30)</span>
</td>
</tr>
<tr class="apply_gen" valign="top" height="35px">
<td colspan="2" class="savebutton">
<input type="button" onclick="SaveConfig();" value="Save" class="button_gen savebutton" name="button">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="resulttable_timeserver">
<thead class="collapsible-jquery" id="resultthead_timeserver">
<tr><td colspan="2">Latest timeserver stats (click to expand/collapse)</td></tr>
</thead>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div id="sortTableContainer" class="sortTableContainer"></div>
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
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons2">
<thead class="collapsible-jquery" id="ntpmerlin_charttools">
<tr><td colspan="2">Chart Display Options (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%"><span style="color:#FFFFFF;background:#2F3A3E;">Time format</span><br /><span style="color:#FFCC00;background:#2F3A3E;">(for tooltips and Last 24h chart axis)</span></th>
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
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="chart_offset">
<tr>
<td colspan="2">Offset (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Data interval</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this);changePeriod(this);" id="Offset_Interval">
<option value="0">Raw</option>
<option value="1">Hours</option>
<option value="2">Days</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Period to display</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="Offset_Period">
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
<thead class="collapsible-jquery" id="chart_drift">
<tr>
<td colspan="2">Drift (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Data interval</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this);changePeriod(this);" id="Drift_Interval">
<option value="0">Raw</option>
<option value="1">Hours</option>
<option value="2">Days</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Period to display</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="Drift_Period">
<option value="0">Last 24 hours</option>
<option value="1">Last 7 days</option>
<option value="2">Last 30 days</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divLineChart_Drift" height="500" /></div>
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
