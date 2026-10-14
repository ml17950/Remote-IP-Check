#print "using ini.bi                by M. Lindner | created ??.??.???? | updated 14.10.2026"

#Include Once "windows.bi"

Namespace ini
	' Returns the ini file to use: the given one, or <exe name>.ini by default
	Private Function resolveFile(ByVal sFile As String) As String
		If sFile <> "" Then Return sFile
		Return Left(Command(0), InStrRev(Command(0), ".")) & "ini"
	End Function

	Function getString(ByVal sSection As String, ByVal sKey As String, ByVal sDefault As String = "", ByVal sFile As String = "") As String
		Dim tmp As String * 1280
		Dim res As Long

		res = GetPrivateProfileString(sSection, sKey, "", tmp, Len(tmp), resolveFile(sFile))

		If res = 0 Then Return sDefault
		Return Left(tmp, res)
	End Function

	Function getInteger(ByVal sSection As String, ByVal sKey As String, ByVal nDefault As Integer = -1, ByVal sFile As String = "") As Integer
		Dim r As String = getString(sSection, sKey, "", sFile)

		If r = "" Then Return nDefault
		Return CInt(r)
	End Function

	Function getSingle(ByVal sSection As String, ByVal sKey As String, ByVal nDefault As Single = -1, ByVal sFile As String = "") As Single
		Dim r As String = getString(sSection, sKey, "", sFile)

		If r = "" Then Return nDefault
		Return CSng(r)
	End Function

	Function getBoolean(ByVal sSection As String, ByVal sKey As String, ByVal nDefault As Byte = 0, ByVal sFile As String = "") As Byte
		Dim r As String = getString(sSection, sKey, "", sFile)

		If r = "" Then Return nDefault

		Select Case LCase(r)
			Case "1", "true", "wahr", "yes", "ja"
				Return 1
			Case Else
				Return 0
		End Select
	End Function

	Sub setString(ByVal sSection As String, ByVal sKey As String, ByVal sValue As String, ByVal sFile As String = "")
		WritePrivateProfileString sSection, sKey, sValue, resolveFile(sFile)
	End Sub

	Sub setInteger(ByVal sSection As String, ByVal sKey As String, ByVal nValue As Integer, ByVal sFile As String = "")
		setString sSection, sKey, Str(nValue), sFile
	End Sub

	Sub setSingle(ByVal sSection As String, ByVal sKey As String, ByVal nValue As Single, ByVal sFile As String = "")
		setString sSection, sKey, Str(nValue), sFile
	End Sub

	Sub setBoolean(ByVal sSection As String, ByVal sKey As String, ByVal nValue As Byte, ByVal sFile As String = "")
		setString sSection, sKey, IIf(nValue = 1, "1", "0"), sFile
	End Sub

	Sub delKey(ByVal sSection As String, ByVal sKey As String, ByVal sFile As String = "")
		WritePrivateProfileString sSection, sKey, NULL, resolveFile(sFile)
	End Sub

	Sub delSection(ByVal sSection As String, ByVal sFile As String = "")
		WritePrivateProfileString sSection, NULL, NULL, resolveFile(sFile)
	End Sub
End Namespace
