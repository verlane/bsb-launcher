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

; Create a folder for commands
if (!FileExist(".\commands")) {
  DirCreate(".\commands")
  FileCopy(".\src\DefaultCommand.ahk", ".\commands\,.ahk")
  FileCopy(".\src\SampleCommand.ahk", ".\commands\g.ahk")
  FileCopy(".\src\DefaultFunctions.ahk", ".\commands\DefaultFunctions.ahk")
}

setting := ClassSetting("Settings.json")
if (!FileExist("Settings.json")) {
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

HotIfWinActive(launcher.GetWindowTitle())
Hotkey "Up", KeyPressEvent
Hotkey "+Tab", KeyPressEvent
Hotkey "^k", KeyPressEvent
Hotkey "Down", KeyPressEvent
Hotkey "Tab", KeyPressEvent
Hotkey "^j", KeyPressEvent
Hotkey "^m", KeyPressEvent
Hotkey "!Enter", KeyPressEvent
Hotkey "!+Enter", KeyPressEvent
Hotkey "^r", (*) => Reload()
Hotkey "F5", (*) => Reload()

KeyPressEvent(key) {
  launcher.KeyPressEvent(key)
}


HotIf

OnMessage 0xB901, CustomMsgHandler
CustomMsgHandler(wParam, lParam, msg, hwnd) {
  if (wParam = 1) {
    KeyPressEvent("Up")
  } else if (wParam = 2) {
    KeyPressEvent("Down")
  } else if (wParam = 3) {
    KeyPressEvent("^m")
  }
  return 0
}

; 종료 시 호출될 함수 정의
OnExit(Cleanup)
Cleanup(exitCode, exitReason) {
  setting.Save()
  MsgBox "스크립트가 종료되었습니다.`n코드: " exitCode "`n이유: " exitReason
}