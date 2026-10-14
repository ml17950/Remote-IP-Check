' Remote-IP-Check
' Periodically fetches the external IP via HTTPS, logs changes and
' connectivity state transitions and runs the matching batch scripts.

#Include Once "inc/ini.bi"
#Include Once "win/wininet.bi"
#Include Once "vbcompat.bi"

Const APP_NAME = "Remote-IP-Check"
Const DEFAULT_URL = "https://api.ipify.org"
Const DEFAULT_INTERVAL = 60
Const DEFAULT_COUNTER = 3
Const MAX_RESPONSE = 256

Dim Shared As String gBasePath
Dim Shared As String gIniFile
Dim Shared As String gLogFile

' Builds the full path of a file next to the executable
Function appFile(ByVal sExt As String) As String
	Return gBasePath & APP_NAME & sExt
End Function

' Replaces the current console line with the given text (no line break)
Sub showStatus(ByVal sText As String)
	Dim As Integer cols = LoWord(Width) - 1

	If cols < 1 Then cols = 79
	Print Chr(13) & Left(sText & Space(cols), cols);
End Sub

' Appends a timestamped line to the log file (and echoes it to the console)
Sub writeLog(ByVal sMessage As String)
	Dim As Integer f = FreeFile
	Dim As String line_ = Format(Now, "yyyy-mm-dd hh:mm:ss") & "  " & sMessage

	' overwrite the status line, then end it so the next status starts fresh
	showStatus line_
	Print
	If Open(gLogFile For Append As #f) = 0 Then
		Print #f, line_
		Close #f
	EndIf
End Sub

' Runs a batch script next to the executable (if it exists) and waits for it
Sub runScript(ByVal sName As String, ByVal sArgs As String = "")
	Dim As String script = appFile("." & sName & ".bat")

	If FileExists(script) = 0 Then
		writeLog "script not found, skipped: " & script
		Return
	EndIf

	writeLog "running script: " & script
	Dim As String cmd = "cmd /c """"" & script & """ " & sArgs & """"
	Shell cmd
End Sub

' Removes whitespace and control characters from both ends of a string
Function cleanResponse(ByVal s As String) As String
	Dim As Integer a = 1, b = Len(s)

	While a <= b AndAlso Asc(Mid(s, a, 1)) <= 32
		a += 1
	Wend
	While b >= a AndAlso Asc(Mid(s, b, 1)) <= 32
		b -= 1
	Wend
	Return Mid(s, a, b - a + 1)
End Function

' Checks that a string looks like an IPv4 or IPv6 address
Function isValidIp(ByVal s As String) As Integer
	Dim As Integer i, c

	If Len(s) < 3 OrElse Len(s) > 45 Then Return 0
	For i = 1 To Len(s)
		c = Asc(Mid(s, i, 1))
		Select Case c
			Case 48 To 57, 65 To 70, 97 To 102, 46, 58 ' 0-9 A-F a-f . :
			Case Else
				Return 0
		End Select
	Next
	Return -1
End Function

' Fetches the external IP from the given URL; returns "" on any failure
Function fetchExternalIp(ByVal sUrl As String) As String
	Dim As HINTERNET hNet, hUrl
	Dim As ZString * (MAX_RESPONSE + 1) buf
	Dim As UInteger nRead
	Dim As String result

	hNet = InternetOpen(APP_NAME, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0)
	If hNet = NULL Then Return ""

	hUrl = InternetOpenUrl(hNet, sUrl, NULL, 0, _
		INTERNET_FLAG_RELOAD Or INTERNET_FLAG_NO_CACHE_WRITE Or INTERNET_FLAG_SECURE, 0)
	If hUrl <> NULL Then
		If InternetReadFile(hUrl, @buf, MAX_RESPONSE, @nRead) <> 0 Then
			buf[nRead] = 0
			result = cleanResponse(buf)
		EndIf
		InternetCloseHandle(hUrl)
	EndIf
	InternetCloseHandle(hNet)

	If isValidIp(result) Then Return result
	Return ""
End Function

' Creates the ini file with default values if it does not exist yet
Sub ensureIniFile()
	If FileExists(gIniFile) Then Return

	ini.setString "config", "check_url", DEFAULT_URL, gIniFile
	ini.setInteger "config", "check_interval", DEFAULT_INTERVAL, gIniFile
	ini.setInteger "config", "check_counter", DEFAULT_COUNTER, gIniFile
	ini.setString "status", "last_ip", "", gIniFile
	ini.setString "status", "this_ip", "", gIniFile
	ini.setString "status", "status", "online", gIniFile
End Sub

' ---------------------------------------------------------------- main

gBasePath = ExePath & "\"
gIniFile = appFile(".ini")
gLogFile = appFile(".log")

ensureIniFile

Dim As String checkUrl, lastIp, thisIp, status, newIp
Dim As Integer interval, maxFails, failCount

writeLog APP_NAME & " started"

Do
	' re-read the config every cycle so changes apply without restart
	checkUrl = ini.getString("config", "check_url", DEFAULT_URL, gIniFile)
	interval = ini.getInteger("config", "check_interval", DEFAULT_INTERVAL, gIniFile)
	maxFails = ini.getInteger("config", "check_counter", DEFAULT_COUNTER, gIniFile)
	If interval < 1 Then interval = DEFAULT_INTERVAL
	If maxFails < 1 Then maxFails = 1

	lastIp = ini.getString("status", "last_ip", "", gIniFile)
	thisIp = ini.getString("status", "this_ip", "", gIniFile)
	status = LCase(ini.getString("status", "status", "online", gIniFile))
	If status <> "offline" Then status = "online"

	showStatus "checking ip..."
	newIp = fetchExternalIp(checkUrl)

	If newIp <> "" Then
		failCount = 0
		showStatus Format(Now, "yyyy-mm-dd hh:mm:ss") & "  current ip: " & newIp

		If status = "offline" Then
			status = "online"
			ini.setString "status", "status", status, gIniFile
			writeLog "system is online again"
			runScript "online", Environ("COMPUTERNAME")
		EndIf

		If newIp <> thisIp Then
			If thisIp = "" Then
				writeLog "initial IP: " & newIp
				ini.setString "status", "this_ip", newIp, gIniFile
			Else
				writeLog "IP changed: " & thisIp & " -> " & newIp
				ini.setString "status", "last_ip", thisIp, gIniFile
				ini.setString "status", "this_ip", newIp, gIniFile
				runScript "changed", thisIp & " " & newIp
			EndIf
		EndIf
	Else
		failCount += 1
		showStatus Format(Now, "yyyy-mm-dd hh:mm:ss") & "  check failed (" & failCount & "/" & maxFails & ")"

		If failCount >= maxFails AndAlso status <> "offline" Then
			status = "offline"
			ini.setString "status", "status", status, gIniFile
			writeLog "system is offline (" & failCount & " failed checks)"
			runScript "offline", Environ("COMPUTERNAME")
		EndIf
	EndIf

	Sleep interval * 1000
Loop
