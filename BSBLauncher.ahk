#Requires Autohotkey v2.0
#SingleInstance force

#Include .\lib\_eval.ahk
#Include .\lib\Array.ahk
#Include .\lib\Map.ahk
#Include .\lib\Misc.ahk
#Include .\lib\String.ahk
#Include .\lib\JSON.ahk
#Include .\lib\Native.ahk
Native.LoadModule(".\lib\ahk-json.dll", ["JSON"])

#Include .\src\ClassArrayMap.ahk
#Include .\src\ClassExeFile.ahk
#Include .\src\ClassExeFileHistory.ahk
#Include .\src\ClassLauncher.ahk
#Include .\src\ClassSetting.ahk

if (!A_IsCompiled) {
  TraySeticon(A_ScriptDir . "\BSBLauncher.ico")
}

SetWorkingDir A_ScriptDir

if (!FileExist(".\commands")) {
  DirCreate(".\commands")
  FileAppend("", ".\commands\,ahk")
}

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
for folderArray in setting.Get("folders") {
  launcher.LoadFolder(folderArray[1], folderArray[2])
}
launcher.LoadExeFileHistories()


^;:: {
  launcher.ShowAsCommandMode()
}

^':: {
  launcher.Show()
}

#Include .\tmp\PrivateScripts.ahk

HotIfWinActive(launcher.GetWindowTitle())
Hotkey "Up", KeyPressEvent
Hotkey "^k", KeyPressEvent
Hotkey "Down", KeyPressEvent
Hotkey "^j", KeyPressEvent
Hotkey "!Enter", KeyPressEvent
Hotkey "!+Enter", KeyPressEvent
Hotkey "^r", (*) => Reload()
Hotkey "F5", (*) => Reload()

KeyPressEvent(key) {
  launcher.KeyPressEvent(key)
}