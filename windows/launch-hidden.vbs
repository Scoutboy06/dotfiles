' Launches the agent with no console window at all.
'
' "powershell.exe -WindowStyle Hidden" is not enough: conhost.exe creates the
' window before PowerShell can hide it, so you get a visible flash. Starting it
' from wscript with intWindowStyle=0 means no console is ever created.

Dim sh, here
Set sh = CreateObject("WScript.Shell")
here = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

sh.Run "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ _
       & here & "vpnctl-agent.ps1""", 0, False
