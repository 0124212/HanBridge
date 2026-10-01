' 翻译爸爸右键版 / Dad's translator right-click launcher (hidden CMD)
' 用法: wscript dad-run.vbs "文件路径"
On Error Resume Next
Dim fso, shell, argPath, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
If WScript.Arguments.Count = 0 Then
  MsgBox "把要翻译的文件点右键 -> 翻译成韩文" & vbCrLf & "Right-click a file -> 翻译成韩文", 64, "翻译爸爸"
  WScript.Quit 0
End If
argPath = WScript.Arguments(0)
cmd = """" & fso.GetParentFolderName(WScript.ScriptFullName) & "\dad-run.bat"" """ & argPath & """"
shell.Popup "翻译中... / Translating, please wait...", 2, "翻译爸爸", 64
shell.Run cmd, 1, True
shell.Popup "完成! / Done! 结果在 translated 文件夹。", 0, "翻译爸爸", 64
