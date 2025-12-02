class ClassLauncher {
  static COMMAND_MODE_PREFIX := ", "

  static LIST_VIEW_HEADER := ["Name", "No", "Ext", "Score", "ExecutedAt", "Args", "FileFullPath"]
  static LIST_VIEW_HEADER_OPTIONS := ["485 Sort", "30 Center", "45", "40 Integer SortDesc", "0 SortDesc", "0", "0"]
  static LIST_VIEW_FILE_FULL_PATH_INDEX := ClassLauncher.LIST_VIEW_HEADER.Length
  static LIST_VIEW_ARGS_INDEX := ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX - 1

  AddToListView(exeFile) {
    this.listView.Add("Icon" . exeFile.iconNumber, exeFile.nameNoExt . " " . exeFile.argStr, "a", exeFile.ext, exeFile.score, exeFile.executedAt, exeFile.argStr, exeFile.fileFullPath)
  }

  ModifyShortcuts() {
    keys := "abcdefghijklmnopqrstuvwxyz"
    Loop this.listView.GetCount() {
      if (A_Index > 9) {
        this.listView.Modify(A_Index, "", , keys[A_Index - 9])
      } else {
        this.listView.Modify(A_Index, "", , A_Index)
      }
    }
  }

  static ToIntOrZero(anyValue) { ; TODO
    try {
      return Integer(anyValue)
    } catch {
      return 0
    }
  }

  __New(setting) {
    this.exeFilesAMap := ClassArrayMap()
    this.exeFileHistoriesAMap := ClassArrayMap()
    this.setting := setting
    this.fileCache := ClassFileCache()
    this.InitializeGui()
    this.FilterExeFiles()
  }

  InitializeGui() {
    this.gui := Gui("-Caption +ToolWindow", "BSB Launcher 2024")
    this.gui.SetFont("s26", "Segoe UI")
    this.gui.OnEvent("Close", (*) => ExitApp())
    this.gui.OnEvent("Escape", (*) => this.EscKeyPressEvent())

    this.keywordEdit := this.gui.Add("Edit", "x6 y8 w606 h50")
    this.keywordEdit.OnEvent("Change", (*) => this.OnKeywordEditEvent())

    this.runButton := this.gui.Add("Button", "default w0 h0", "OK")
    this.runButton.OnEvent("Click", (*) => this.Submit())

    this.listView := this.gui.Add("ListView", "x6 y64 h490 w606 +Grid -Hdr +Multi", ClassLauncher.LIST_VIEW_HEADER) ; TODO +Multi
    this.listView.SetFont("s12", "Segoe UI")

    ; Create an ImageList so that the ListView can display some icons:
    this.imageListID1 := IL_Create(10)
    this.ImageListID2 := IL_Create(10, 10, true)  ; A list of large icons to go with the small ones.

    ; Attach the ImageLists to the ListView so that it can later display the icons:
    this.listView.SetImageList(this.imageListID1)
    this.listView.SetImageList(this.imageListID2)

    ; Apply control events:
    this.listView.OnEvent("Click", ObjBindMethod(this, "HandleClick"))
    this.listView.OnEvent("DoubleClick", ObjBindMethod(this, "RunFile"))
    this.listView.OnEvent("ContextMenu", ObjBindMethod(this, "ShowContextMenu"))

    ; Create a popup menu to be used as the context menu:
    this.contextMenu := Menu()
    this.contextMenu.Add("Open", ObjBindMethod(this, "RunFile"))
    this.contextMenu.Add("Delete from history(&D)", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add()
    this.contextMenu.Add("+5 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add("+1 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add("-1 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add("-5 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add()
    this.contextMenu.Add("Properties", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Default := "Open"  ; Make "Open" a bold font to indicate that double-click does the same thing.
  }

  GetWindowTitle() {
    return this.gui.Title
  }

  ShowAsCommandMode() {
    this.gui.Show("w620 h562")
    WinSetTransparent 240, "A"
    if (this.keywordEdit.Value.RegExMatch("i)^" . ClassLauncher.COMMAND_MODE_PREFIX . "+")) {
      this.FilterExeFiles(ClassLauncher.COMMAND_MODE_PREFIX)
      this.keywordEdit.Focus()
      Send("{Home}{Right 2}{Shift Down}{End}{Shift Up}")
    } else {
      this.keywordEdit.Value := ClassLauncher.COMMAND_MODE_PREFIX
      this.keywordEdit.Focus()
      Send("{End}")
      this.FilterExeFiles(this.keywordEdit.Value)
    }
  }

  Show(keyword := "") {
    this.gui.Show("w620 h562")
    WinSetTransparent 240, "A"
    if (keyword) {
      this.keywordEdit.Value := keyword
      this.keywordEdit.Focus()
      Send("{End}")
    } else {
      this.keywordEdit.Focus()
    }
    this.FilterExeFiles(this.keywordEdit.Value)
  }

  Hide() {
    this.gui.Hide()
  }

  OnKeywordEditEvent(*) {
    SetTimer () => this.FilterExeFiles(this.keywordEdit.value), -100
  }

  Submit(*) {
    this.RunFile()
  }

  GetMapKey(fileFullPath, argStr) {
    return fileFullPath ">" Trim(StrLower(argStr))
  }

  RunFile(*) {
    if (this.listView.GetText(1, ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX) == "eval") { ; for eval
      A_Clipboard := this.listView.GetText(1, 1)
      this.Hide()
      return
    }

    pressLCtrl := GetKeyState("LCtrl", "P") ; the value is 1 at pressed
    pressLShift := GetKeyState("LShift", "P")
    pressLAlt := GetKeyState("LAlt", "P")
    metaKeyFlags := pressLCtrl . pressLShift . pressLAlt

    focusedRowNumber := this.listView.GetNext(0, "F")
    fileFullPath := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX)
    storedArgs := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_ARGS_INDEX)
    try {
      this.Hide()
      exeFile := this.exeFilesAMap.Get(fileFullPath)
      argStr := this.keywordEdit.value.Split(" ").Slice(2).Join(" ")

      if (argStr) {
        mapKey := this.GetMapKey(fileFullPath, argStr)
        exeFile.Run(argStr, metaKeyFlags)
      } else {
        mapKey := this.GetMapKey(fileFullPath, storedArgs)
        exeFile.Run(storedArgs, metaKeyFlags)
      }
      if (this.exeFileHistoriesAMap.Has(mapKey)) {
        exeFileHistory := this.exeFileHistoriesAMap.Get(mapKey)
      } else {
        exeFileHistory := ClassExeFileHistory(exeFile, argStr)
      }
      exeFileHistory.argStr := argStr
      exeFileHistory.executedAt := FormatTime(A_Now, "yyyyMMddHHmmss")
      this.exeFileHistoriesAMap.Push(mapKey, exeFileHistory)
      this.exeFileHistoriesAMap.Sort("N R", "executedAt")
      this.setting.Set("exeFileHistories", this.exeFileHistoriesAMap.Slice(1, 65536))
      ; this.setting.Save()
    } catch Error as err {
      errorLog := "Error occurred at line " . err.Line . "`n"
      errorLog .= "Error Message: " . err.Message . "`n"
      errorLog .= "Error Type: " . err.What . "`n"
      errorLog .= "Stack Trace:`n" . err.Stack . "`n"

      FileAppend(errorLog, A_ScriptDir . "\error_log.txt")

      MsgBox("Could not open " . fileFullPath . ".`n"
        . "Specifically: " . err.Message . "`n"
        . "Error details have been logged to error_log.txt")
    }
  }

  HandleClick(*) {
    focusedRowNumber := this.listView.GetNext(0, "F")
    this.keywordEdit.value := this.listView.GetText(focusedRowNumber, 1)
  }

  ; In response to right-click or Apps key.
  ShowContextMenu(listView, item, isRightClick, x, y) {
    ; Show the menu at the provided coordinates, X and Y.  These should be used
    ; because they provide correct coordinates even if the user pressed the Apps key:
    this.contextMenu.Show(x, y)
  }

  ; The user selected "Open" or "Properties" in the context menu.
  ContextMenuEvent(itemName, *) {
    focusedRowNumber := 0
    Loop {
      focusedRowNumber := this.listView.GetNext(focusedRowNumber)
      if (!focusedRowNumber) { ; No row is focused.
        if (InStr(itemName, "Delete from history")) {
          this.FilterExeFiles(this.keywordEdit.value)
        }
        return
      }
      fileFullPath := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX)
      argStr := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_ARGS_INDEX)
      mapKey := this.GetMapKey(fileFullPath, argStr)
      try {
        exeFile := this.exeFilesAMap.Get(fileFullPath)
        if (RegExMatch(itemName, "i)^([`+`-][0-9]+) Score$", &SubPat)) { ; User selected "Open" from the context menu.
          exeFile.AddScore(SubPat[1])
          this.FilterExeFiles(this.keywordEdit.value)
          baseScore := ClassLauncher.ToIntOrZero(this.setting.Get("exeFiles", fileFullPath, "additionalScore"))
          this.setting.Set("exeFiles", fileFullPath, "additionalScore", baseScore + Integer(SubPat[1]))
          ; this.setting.Save()
        } else if (InStr(itemName, "Delete from history")) {
          this.exeFileHistoriesAMap.Delete(mapKey)
          this.setting.Set("exeFileHistories", this.exeFileHistoriesAMap.GetAll())
          ; this.setting.Save()
        } else {
          exeFile.Properties()
        }
      } catch Error as err {
        MsgBox("Could not perform requested action on " fileFullPath ".`nSpecifically: " err.Message)
      }
    }
  }

  LoadFolder(folder, baseScore := 0, forceRefresh := false) {
    if not folder
      return

    if SubStr(folder, -1, 1) = "\"
      folder := SubStr(folder, 1, -1)

    sfi_size := A_PtrSize + 688
    sfi := Buffer(sfi_size)

    Loop Files, folder "\*", "R"
    {
      fileName := A_LoopFilePath

      SplitPath(fileName, , , &fileExt)
      if not fileExt ~= "i)\A(EXE|BAT|CMD|LNK|AHK|AHK2)\z"
      {
        continue
      }

      ; Determine ExtID for icon caching
      if fileExt ~= "i)\A(EXE|ICO|ANI|CUR|LNK|AHK|AHK2)\z"
      {
        ExtID := fileExt
        iconNumber := 0
      }
      else
      {
        ExtID := 0
        Loop 7
        {
          ExtChar := SubStr(fileExt, A_Index, 1)
          if not ExtChar
            break
          ExtID := ExtID | (Ord(ExtChar) << (8 * (A_Index - 1)))
        }
        ; Check icon cache (unless force refresh)
        iconNumber := forceRefresh ? 0 : this.fileCache.GetIconNumber(ExtID)
      }

      ; Load icon if not cached
      if not iconNumber
      {
        if not DllCall("Shell32\SHGetFileInfoW", "Str", fileName
          , "Uint", 0, "Ptr", sfi, "UInt", sfi_size, "UInt", 0x101)
          iconNumber := 9999999
        else
        {
          hIcon := NumGet(sfi, 0, "Ptr")
          iconNumber := DllCall("ImageList_ReplaceIcon", "Ptr", this.imageListID1, "Int", -1, "Ptr", hIcon) + 1
          ; Cache the icon number
          this.fileCache.SetIconNumber(ExtID, iconNumber)
        }
      }

      additionalScore := ClassLauncher.ToIntOrZero(this.setting.Get("exeFiles", A_LoopFileFullPath, "additionalScore"))
      score := baseScore + additionalScore
      exeFile := ClassExeFile(iconNumber, score, A_LoopFileFullPath)
      this.exeFilesAMap.Push(A_LoopFileFullPath, exeFile)
    }
    this.exeFilesAMap.Sort("N R", "Score")
  }

  LoadExeFileHistories() {
    exeFileHistories := this.setting.Get("exeFileHistories")
    if (!exeFileHistories) {
      return
    }

    for exeFileHistoryMap in exeFileHistories {
      fileFullPath := exeFileHistoryMap["exeFile"]["fileFullPath"]
      argStr := exeFileHistoryMap["argStr"]
      mapKey := this.GetMapKey(fileFullPath, argStr)
      if (this.exeFilesAMap.Has(fileFullPath)) {
        exeFile := this.exeFilesAMap.Get(fileFullPath)
        exeFileHistory := ClassExeFileHistory(exeFile, argStr)
        exeFileHistory.executedAt := exeFileHistoryMap["executedAt"]
        this.exeFileHistoriesAMap.Push(mapKey, exeFileHistory)
      }
    }
  }

  AddExeFileToListView2(targetExeFilesAMap, needleKeyword := "", isHistory := true) {
    for exeFile in targetExeFilesAMap.GetAll() {
      if (!isHistory && (this.exeFileHistoriesAMap.Has(exeFile.fileFullPath) || this.exeFileHistoriesAMap.Has(exeFile.fileFullPath . ">"))) {
        continue
      }
      if (this.listView.GetCount() > 18) {
        break
      }
      needleKeywords := needleKeyword.Split(" ")
      command := ""
      if (needleKeywords.Length > 0) {
        command := needleKeywords[1]
      }
      argStr := ""
      if (needleKeywords.Length > 1) {
        argStr := needleKeywords.Slice(2).Join(" ")
      }

      addIt := false
      if (RegExMatch(command, "i)^([a-z_,`-]+) ", &SubPat)) {
        if (InStr(exeFile.NameNoExt, SubPat[1]) && (InStr(exeFile.Ext, "ahk") || InStr(exeFile.Ext, "ahk2")) && (!argStr || InStr(exeFile.ArgStr, argStr))) {
          addIt := true
        }
      } else if (!command || InStr(exeFile.NameNoExt, command) && (!argStr || InStr(exeFile.ArgStr, argStr))) {
        addIt := true
      }
      if (addIt) {
        this.AddToListView(exeFile)
      }
    }
  }

  AddExeFileToListView(targetExeFilesAMap, needleKeyword := "", isHistory := true) {
    this.AddExeFileToListView2(targetExeFilesAMap, needleKeyword, isHistory)
    if (this.listView.GetCount() < 1) {
      needleKeywords := needleKeyword.Split(" ")
      command := ""
      if (needleKeywords.Length > 0) {
        command := needleKeywords[1]
      }
      this.AddExeFileToListView2(targetExeFilesAMap, command, isHistory)
    }
  }

  SpaceToPlus(str) {
    result := ""
    parenLevel := 0

    ; Loop through each character in the string
    loop parse, str
    {
        char := A_LoopField

        ; Track the current level of parentheses
        if (char = "(")
            parenLevel++
        else if (char = ")")
            parenLevel--

        ; Mark characters inside parentheses to exclude them from replacement
        if (parenLevel > 0)
            result .= "¶" . char  ; Temporary marker for characters inside parentheses
        else
            result .= char
    }

    ; Keep operators and numbers, replace everything else with space
    ; Preserve ¶ marker for parentheses content
    result := RegExReplace(result, "[^\d\+\-\*\/\.() ¶]", " ")

    ; Add " + " between numbers that are separated ONLY by whitespace (no operators)
    ; This regex checks if there's only whitespace between numbers
    while RegExMatch(result, "(\d+\.?\d*)\s+(\d+\.?\d*)", &match) {
        result := StrReplace(result, match[0], match[1] . " + " . match[2], , , 1)
    }

    ; Remove temporary markers and restore the original content inside parentheses
    result := StrReplace(result, "¶")

    return result
  }

  FilterExeFiles(needleKeyword := "") {
    this.listView.Delete()

    try {
      formula := StrReplace(needleKeyword, ",", "")
      if (StrLen(formula) > 1 && !RegExMatch(needleKeyword, "^,.+?")) {
        ; Check if it starts with a valid math character first
        if (RegExMatch(Trim(formula), "^[\d\-~!\x28]")) {
          formula := this.SpaceToPlus(formula)
          ; Check if the formula is a valid math expression
          if (eval(formula, true)) {
            result := Format("{:.10f}", eval(formula))
            result := RegExReplace(result, "0+$", "") ; replace 0.1000 to 0.1
            intValue := Integer(result)
            if (result == intValue) {
              result := intValue
              result := RegExReplace(result, "(\d)(?=(\d{3})+(?!\d))", "$1,")
            }
            this.listView.Add(, result, , , , , , "eval")
            return
          }
        }
      }
    } catch {
    }

    ; Gather a list of file names from the selected folder and append them to the ListView:
    this.listView.Opt("-Redraw")  ; Improve performance by disabling redrawing during load.
    if (needleKeyword == "" && this.exeFileHistoriesAMap.Length() > 0) {
      this.AddExeFileToListView(this.exeFileHistoriesAMap, needleKeyword)
    } else {
      this.AddExeFileToListView(this.exeFileHistoriesAMap, needleKeyword)
      this.AddExeFileToListView(this.exeFilesAMap, needleKeyword, false)
    }

    this.listView.Opt("+Redraw -Hdr")
    for i, header in ClassLauncher.LIST_VIEW_HEADER {
      this.listView.ModifyCol(i, ClassLauncher.LIST_VIEW_HEADER_OPTIONS[i])
    }

    this.ModifyShortcuts()

    this.listView.Modify(1, "Focus Select")
  }

  RefreshCache(folders := "") {
    ; Clear current data
    this.exeFilesAMap := ClassArrayMap()
    this.fileCache.Clear()

    ; Reload folders with force refresh
    if (!folders) {
      folders := this.setting.Get("folders")
    }

    for folderArray in folders {
      this.LoadFolder(folderArray[1], folderArray[2], true)
    }

    ; Save cache
    this.fileCache.Save()

    ; Refresh display
    this.FilterExeFiles(this.keywordEdit.value)

    ; Show notification
    iconCount := this.fileCache.GetCachedIconsCount()
    ToolTip("Cache refreshed: " iconCount " icons cached")
    SetTimer(() => ToolTip(), -2000)
  }

  SaveCache() {
    this.fileCache.Save()
  }

  EscKeyPressEvent(*) {
    try {
      HWND := ControlGetFocus("A")
    } catch TargetError {
      return
    }
    if (HWND == this.keywordEdit.HWND) {
      this.gui.Hide()
    } else if (HWND == this.listView.HWND) {
      this.keywordEdit.Focus()
    }
  }

  KeyPressEvent(thisHotkey) {
    try {
      HWND := ControlGetFocus("A")
    } catch TargetError {
      return
    }
    focusedRowNumber := this.listView.GetNext(0, "F") ; Find the focused row.
    if (thisHotkey == "Up" || thisHotkey == "^k" || thisHotkey == "+Tab") {
      focusedRowNumber := Max(focusedRowNumber - 1, 1)
    } else if (thisHotkey == "Down" || thisHotkey == "^j" || thisHotkey == "Tab") {
      if (this.listView.GetText(focusedRowNumber) == this.keywordEdit.value) {
        focusedRowNumber := Min(focusedRowNumber + 1, this.listView.GetCount())
      } else {
        focusedRowNumber := Max(focusedRowNumber, 1)
      }
    } else if (thisHotkey == "!Enter" || thisHotkey == "!+Enter" || thisHotkey == "^m") {
      this.RunFile()
    }
    this.listView.Modify(0, "-Select")
    if (this.listView.GetCount() > 0) {
      this.listView.Modify(focusedRowNumber, "Focus Select")
      this.keywordEdit.value := this.listView.GetText(focusedRowNumber)
    }
    this.keywordEdit.Focus()
  }
}