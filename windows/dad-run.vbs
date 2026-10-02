' Dad's translator right-click launcher (hidden CMD) / 우클릭 실행기 (숨김 CMD)
' Usage: wscript dad-run.vbs "filepath" / 사용법: wscript dad-run.vbs "파일경로"
On Error Resume Next
Dim fso, shell, argPath, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
If WScript.Arguments.Count = 0 Then
  MsgBox "Right-click a file -> Translate to Korean" & vbCrLf & "파일 우클릭 → 한국어로 번역", 64, "翻译爸爸"
  WScript.Quit 0
End If
argPath = WScript.Arguments(0)
cmd = """" & fso.GetParentFolderName(WScript.ScriptFullName) & "\dad-run.bat"" """ & argPath & """"
shell.Popup "Translating, please wait... / 번역 중, 잠시만 기다리세요...", 2, "翻译爸爸", 64
shell.Run cmd, 1, True
shell.Popup "Done! Results in translated folder. / 완료! translated 폴더에서 확인.", 0, "翻译爸爸", 64
