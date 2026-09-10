' Starts the watcher with no console window at all.
'
' powershell.exe -WindowStyle Hidden still flashes a console for a moment at
' logon; launching it through WScript.Shell with intWindowStyle 0 does not.

Dim shell, scriptPath
Set shell = CreateObject("WScript.Shell")
scriptPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\")) & "spotify-widget-watcher.ps1"

shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptPath & """", 0, False
