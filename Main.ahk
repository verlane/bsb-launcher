#Requires Autohotkey v2.0
#SingleInstance force

#Include .\lib\_eval.ahk
#Include .\lib\Array.ahk
#Include .\lib\Map.ahk
#Include .\lib\Misc.ahk
#Include .\lib\String.ahk
#Include .\lib\JSON.ahk

#Include .\src\ClassSetting.ahk
#Include .\src\ClassLauncher.ahk
#Include .\src\ClassExeFile.ahk

SetWorkingDir A_ScriptDir

setting := ClassSetting("Settings.json")
launcher := ClassLauncher(setting)

launcher.LoadFolder(".\commands", 20)
launcher.LoadFolder("C:\Users\gosoo\Dropbox\Program Files\putty\Shortcuts", 10)
launcher.LoadFolder(A_StartMenu)
launcher.LoadFolder(A_StartMenuCommon)
launcher.LoadExeFileHistories()
launcher.FilterExeFiles()

^,:: {
  launcher.Show()
}

HotIfWinActive(launcher.GetWindowTitle())
Hotkey "Up", KeyPressEvent
Hotkey "Down", KeyPressEvent

KeyPressEvent(key) {
  launcher.KeyPressEvent(key)
}