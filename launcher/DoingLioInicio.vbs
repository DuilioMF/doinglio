Set app = CreateObject("WScript.Shell")
q = Chr(34)
splashPath = "C:\Sistemas\DoingLioLauncher\reloj_inicio.hta"
Set splash = Nothing
On Error Resume Next
If CreateObject("Scripting.FileSystemObject").FileExists(splashPath) Then
    Set splash = app.Exec("mshta.exe " & q & splashPath & q)
End If
On Error GoTo 0
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & q & "C:\Sistemas\DoingLioLauncher\abrir_doinglio.ps1" & q
code = app.Run(cmd, 0, True)
On Error Resume Next
If Not splash Is Nothing Then splash.Terminate
On Error GoTo 0
If code <> 0 Then
    app.Run "notepad.exe " & q & "C:\Sistemas\DoingLioLauncher\inicio.log" & q, 1, False
    MsgBox "No se pudo iniciar DoingLio. Se abrio el registro con el error.", vbExclamation, "DoingLio"
End If
