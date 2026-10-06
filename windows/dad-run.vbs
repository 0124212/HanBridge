' Dad's translator right-click launcher (hidden CMD) / 우클릭 실행기 (숨김 CMD)
' Usage: wscript dad-run.vbs "filepath" / 사용법: wscript dad-run.vbs "파일경로"
On Error Resume Next
Dim fso, shell, argPath, cmd, rc
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
If WScript.Arguments.Count = 0 Then
  MsgBox "중국어 파일을 HanBridge 아이콘에 드래그하세요", 64, "HanBridge"
  WScript.Quit 0
End If
argPath = WScript.Arguments(0)
cmd = """" & fso.GetParentFolderName(WScript.ScriptFullName) & "\dad-run.bat"" """ & argPath & """"
shell.Popup "번역 중, 잠시만 기다리세요...", 2, "HanBridge", 64
rc = shell.Run(cmd, 1, True)
If rc <> 0 Then
  shell.Popup "실패했습니다. 원본은 그대로 있습니다. 다시 시도하세요.", 0, "HanBridge", 16
Else
  shell.Popup "완료! 바탕화면 translated 폴더를 보세요.", 0, "HanBridge", 64
End If
