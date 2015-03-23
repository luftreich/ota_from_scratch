<%@ page language="java" import="java.util.*" pageEncoding="utf-8"%>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>
<!DOCTYPE HTML>
<html lang="en-US">
<head>
	<base href="<%=basePath%>">
	<title></title>
</head>
<body>
	<form action="update" method="POST">
		id:<input name="id" type="text" value="1000"/><br>
		updating_apk_version:<input name="updating_apk_version" type="text" value="1.0"/><br>
		brand:<input name="brand" type="text" value="MBX"/><br>
		device:<input name="device" type="text" value="m201"/><br>
		board:<input name="board" type="text" value="m201"/><br>
		mac:<input name="mac" type="text" value="172.17.72.254"/><br>
		firmware:<input name="firmware" type="text" value="00442023"/><br>
		android:<input name="android" type="text" value="4.4.2"/><br>
		time:<input name="time" type="text" value="Mon 23 Mar 2015 11:54:17 AM HKT"/><br>
		builder:<input name="builder" type="text" value="LT"/><br>
		fingerprint:<input name="fingerprint" type="text" value="MBX/m201/m201:4.4.2/KOT49H/20150318.V0823:user/test-keys"/><br>
		debug_conf:<input name="debug_conf" type="text" value="http://192.168.1.20:8080/otaupdate/debug.conf"/><br>
		update_conf:<input name="update_conf" type="text" value="http://192.168.1.20:8080/otaupdate/update.conf"/><br>
		<input type="submit" value="提交Submit" />
	</form>
</body>
</html>
