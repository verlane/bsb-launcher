#Include DefaultFunctions.ahk

if (FileExist(arg0Command . ".ahk")) { ; Command File
  arg0CommandFilename := arg0Command . ".ahk"
  Run(A_AhkPath . " " . arg0CommandFilename . " " . arg0MetaKeyFlags . " " . arg0Command . " " . arg0Original)
} else {
  MsgBox "Not Found"
}
