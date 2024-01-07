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
if not FileExist("Settings.json") {
  setting.Set("folders", [
    [".\commands", 20],
    [A_StartMenu, 0],
    [A_StartMenuCommon, 0]
  ])
  setting.Save()
}

launcher := ClassLauncher(setting)
for index, folderArray in setting.Get("folders") {
  launcher.LoadFolder(folderArray[1], folderArray[2])
}
launcher.LoadExeFileHistories()
launcher.FilterExeFiles()


^,:: {
  launcher.Show()
}

#Include .\tmp\PrivateScripts.ahk

HotIfWinActive(launcher.GetWindowTitle())
Hotkey "Up", KeyPressEvent
Hotkey "Down", KeyPressEvent

KeyPressEvent(key) {
  launcher.KeyPressEvent(key)
}
