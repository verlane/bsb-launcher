; In case of "ri app 123", the result is below:
pressLCtrl := false
pressLShift := false
pressLAlt := false
arg0MetaKeyFlags := "000" ; 000 Lctrl, Lshift, Lalt
arg0Command := "" ; ri
arg0Original := "" ; app 123
arg0Regex := "" ; app.*123
arg0Array := "" ; [app, 1234]
arg0Str := "" ; ri app 123

if (A_Args.Length > 0) {
  arg0Str := A_Args.Slice(2).Join(" ")
  arg0MetaKeyFlags := A_Args[1]
  pressLCtrl := SubStr(arg0MetaKeyFlags, 1, 1) == "1"
  pressLShift := SubStr(arg0MetaKeyFlags, 2, 1) == "1"
  pressLAlt := SubStr(arg0MetaKeyFlags, 3, 1) == "1"
  try {
    arg0Command := A_Args[2]
    arg0Array := A_Args.Slice(3)
    arg0Original := arg0Array.Join(" ")
    arg0Regex := arg0Array.Join(".*")
  } catch IndexError as err {
  }
}

RunCommand(filenameWithoutSuffix, arg0MetaKeyFlags := "", command := "", arg0Original := "") {
  if (arg0Original == "") {
    arg0Original := command
  }
  RunWait(A_AhkPath . " " . A_ScriptDir . "\" . filenameWithoutSuffix . ".ahk " . arg0MetaKeyFlags . " " . command . " " . arg0Original)
}

UrlEncode(str, sExcepts := "-_.", enc := "UTF-8") {
  hex := "00", func := "msvcrt\swprintf"
  buff := Buffer(StrPut(str, enc)), StrPut(str, buff, enc)
  encoded := ""
  Loop {
    if (!b := NumGet(buff, A_Index - 1, "UChar"))
      break
    ch := Chr(b)
    ; "is alnum" is not used because it is locale dependent.
    if (b >= 0x41 && b <= 0x5A ; A-Z
      || b >= 0x61 && b <= 0x7A ; a-z
      || b >= 0x30 && b <= 0x39 ; 0-9
      || InStr(sExcepts, Chr(b), true))
      encoded .= Chr(b)
    else {
      DllCall(func, "Str", hex, "Str", "%%%02X", "UChar", b, "Cdecl")
      encoded .= hex
    }
  }
  return encoded
}

; Decode precent encoding
UrlDecode(Url, Enc := "UTF-8") {
  Pos := 1
  Loop {
    Pos := RegExMatch(Url, "i)(?:%[\da-f]{2})+", &code, Pos++)
    If (Pos = 0)
      Break
    code := code[0]
    var := Buffer(StrLen(code) // 3, 0)
    code := SubStr(code, 2)
    loop Parse code, "`%"
      NumPut("UChar", Integer("0x" . A_LoopField), var, A_Index - 1)
    Url := StrReplace(Url, "`%" code, StrGet(var, Enc))
  }
  return Url
}