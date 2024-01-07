#Requires Autohotkey v2.0
#SingleInstance force

SetWorkingDir A_ScriptDir

DirCreate ".\tmp"
if FileExist(".\tmp\PrivateScripts.ahk") {
  FileDelete ".\tmp\PrivateScripts.ahk"
}

FileAppend("", ".\tmp\PrivateScripts.ahk")
Loop Files ".\private\*.ahk" {
  contents := FileRead(A_LoopFileFullPath)
  FileAppend(contents "`n", ".\tmp\PrivateScripts.ahk")
}

Run(".\BSBLauncher.ahk")