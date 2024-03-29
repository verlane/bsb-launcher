class ClassLauncher {
  static COMMAND_MODE_PREFIX := ", "

  static LIST_VIEW_HEADER := ["Name", "No", "Ext", "Score", "ExecutedAt", "Args", "FileFullPath"]
  static LIST_VIEW_HEADER_OPTIONS := ["485 Sort", "30 Center", "45", "40 Integer SortDesc", "0 SortDesc", "0", "0"]
  static LIST_VIEW_FILE_FULL_PATH_INDEX := ClassLauncher.LIST_VIEW_HEADER.Length
  static LIST_VIEW_ARGS_INDEX := ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX - 1
  AddToListView(exeFile, listView) {
    listView.Add("Icon" . exeFile.iconNumber, exeFile.nameNoExt . " " . exeFile.argStr, "a", exeFile.ext, exeFile.score, exeFile.executedAt, exeFile.argStr, exeFile.fileFullPath)
  }
  ModifyShortcuts(listView){
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
    this.InitializeGui()
    this.FilterExeFiles()
  }

  InitializeGui() {
    this.gui := Gui("+OwnDialogs -Caption +Owner", "BSB Launcher 2024")
    this.gui.SetFont("s26", "Segoe UI")
    this.gui.OnEvent("Close", (*) => ExitApp())
    this.gui.OnEvent("Escape", (*) => this.EscKeyPressEvent())

    this.keywordEdit := this.gui.Add("Edit", "x6 y8 w606 h50")
    this.keywordEdit.OnEvent("Change", (*) => this.OnKeywordEditEvent())

    this.runButton := this.gui.Add("Button", "default w0 h0", "OK")
    this.runButton.OnEvent("Click", (*) => this.Submit())

    this.listView := this.gui.Add("ListView", "x6 y64 h490 w606 +Grid -Hdr -Multi", ClassLauncher.LIST_VIEW_HEADER) ; TODO +Multi
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
        mapKey := fileFullPath ">" argStr
        exeFile.Run(argStr, metaKeyFlags)
      } else {
        mapKey := fileFullPath ">" storedArgs
        exeFile.Run(storedArgs, metaKeyFlags)
      }
      if (this.exeFileHistoriesAMap.Has(mapKey)) {
        exeFileHistory := this.exeFileHistoriesAMap.Get(mapKey)
      } else {
        exeFileHistory := ClassExeFileHistory(exeFile, argStr)
      }
      exeFileHistory.executedAt := FormatTime(A_Now, "yyyyMMddHHmmss")
      this.exeFileHistoriesAMap.Push(mapKey, exeFileHistory)
      this.exeFileHistoriesAMap.Sort("N R", "executedAt")
      this.setting.Set("exeFileHistories", this.exeFileHistoriesAMap.Slice(1, 128))
      this.setting.Save()
    } catch Error as err {
      MsgBox("Could not open " . fileFullPath . ".`nSpecifically: " . err.Message)
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
    focusedRowNumber := this.listView.GetNext(0, "F")  ; Find the focused row.
    if not focusedRowNumber  ; No row is focused.
      return

    currentRowNumber := focusedRowNumber + A_Index - 1
    fileFullPath := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX)
    argStr := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_ARGS_INDEX)
    mapKey := fileFullPath ">" argStr
    try {
      exeFile := this.exeFilesAMap.Get(fileFullPath)
      if (RegExMatch(itemName, "i)^([`+`-][0-9]+) Score$", &SubPat)) { ; User selected "Open" from the context menu.
        exeFile.AddScore(SubPat[1])
        this.FilterExeFiles(this.keywordEdit.value)
        baseScore := ClassLauncher.ToIntOrZero(this.setting.Get("exeFiles", fileFullPath, "additionalScore"))
        this.setting.Set("exeFiles", fileFullPath, "additionalScore", baseScore + Integer(SubPat[1]))
        this.setting.Save()
      } else if (InStr(itemName, "Delete from history")) {
        this.exeFileHistoriesAMap.Delete(mapKey)
        this.FilterExeFiles(this.keywordEdit.value)
        this.setting.Set("exeFileHistories", this.exeFileHistoriesAMap.GetAll())
        this.setting.Save()
      } else {
        exeFile.Properties()
      }
    } catch Error as err {
      MsgBox("Could not perform requested action on " fileFullPath ".`nSpecifically: " err.Message)
    }
  }

  LoadFolder(folder, baseScore := 0) {
    static iconMap := Map()

    if not folder  ; The user canceled the dialog.
      return

    ; Check if the last character of the folder name is a backslash, which happens for root
    ; directories such as C:\. If it is, remove it to prevent a double-backslash later on.
    if SubStr(folder, -1, 1) = "\"
      folder := SubStr(folder, 1, -1)  ; Remove the trailing backslash.

    ; Calculate buffer size required for SHFILEINFO structure.
    sfi_size := A_PtrSize + 688
    sfi := Buffer(sfi_size)

    Loop Files, folder "\*", "R"
    {
      fileName := A_LoopFilePath  ; Must save it to a writable variable for use below.

      ; Build a unique extension ID to avoid characters that are illegal in variable names,
      ; such as dashes. This unique ID method also performs better because finding an item
      ; in the array does not require search-loop.
      SplitPath(fileName, , , &fileExt)  ; Get the file's extension.
      if not fileExt ~= "i)\A(EXE|BAT|LNK|AHK|AHK2)\z"
      {
        continue
      }

      if fileExt ~= "i)\A(EXE|ICO|ANI|CUR|LNK)\z"
      {
        ExtID := fileExt  ; Special ID as a placeholder.
        iconNumber := 0  ; Flag it as not found so that these types can each have a unique icon.
      }
      else  ; Some other extension/file-type, so calculate its unique ID.
      {
        ExtID := 0  ; Initialize to handle extensions that are shorter than others.
        Loop 7   ; Limit the extension to 7 characters so that it fits in a 64-bit value.
        {
          ExtChar := SubStr(fileExt, A_Index, 1)
          if not ExtChar  ; No more characters.
            break
          ; Derive a Unique ID by assigning a different bit position to each character:
          ExtID := ExtID | (Ord(ExtChar) << (8 * (A_Index - 1)))
        }
        ; Check if this file extension already has an icon in the ImageLists. If it does,
        ; several calls can be avoided and loading performance is greatly improved,
        ; especially for a folder containing hundreds of files:
        iconNumber := iconMap.Has(ExtID) ? iconMap[ExtID] : 0
      }
      if not iconNumber  ; There is not yet any icon for this extension, so load it.
      {
        ; Get the high-quality small-icon associated with this file extension:
        if not DllCall("Shell32\SHGetFileInfoW", "Str", fileName
          , "Uint", 0, "Ptr", sfi, "UInt", sfi_size, "UInt", 0x101)  ; 0x101 is SHGFI_ICON+SHGFI_SMALLICON
          iconNumber := 9999999  ; Set it out of bounds to display a blank icon.
        else ; Icon successfully loaded.
        {
          ; Extract the hIcon member from the structure:
          hIcon := NumGet(sfi, 0, "Ptr")
          ; Add the HICON directly to the small-icon and large-icon lists.
          ; Below uses +1 to convert the returned index from zero-based to one-based:
          iconNumber := DllCall("ImageList_ReplaceIcon", "Ptr", this.imageListID1, "Int", -1, "Ptr", hIcon) + 1
          DllCall("ImageList_ReplaceIcon", "Ptr", this.imageListID2, "Int", -1, "Ptr", hIcon)
          ; Now that it's been copied into the ImageLists, the original should be destroyed:
          DllCall("DestroyIcon", "Ptr", hIcon)
          ; Cache the icon to save memory and improve loading performance:
          iconMap[ExtID] := iconNumber
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
      mapKey := fileFullPath ">" argStr
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
        this.AddToListView(exeFile, this.listView)
      }
      if (this.listView.GetCount() > 18) {
        break
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

  FilterExeFiles(needleKeyword := "") {
    this.listView.Delete()

    try {
      if (StrLen(needleKeyword) > 1) {
        result := Format("{:.10f}", eval(needleKeyword))
        result := RegExReplace(result, "0+$", "") ; replace 0.1000 to 0.1
        intValue := Integer(result)
        if (result == intValue) {
          result := intValue
          result := RegExReplace(result, "(\d)(?=(\d{3})+(?!\d))", "$1,")
        }
        this.listView.Add(, result, , , , , , "eval")
        return
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

    this.ModifyShortcuts(this.listView)

    this.listView.Modify(1, "Focus Select")
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
    if (thisHotkey == "Up" || thisHotkey == "^k") {
      focusedRowNumber := Max(focusedRowNumber - 1, 1)
    } else if (thisHotkey == "Down" || thisHotkey == "^j") {
      focusedRowNumber := Min(focusedRowNumber + 1, this.listView.GetCount())
    } else if (thisHotkey == "!Enter" || thisHotkey == "!+Enter") {
      this.RunFile()
    }
    this.listView.Modify(0, "-Select")
    if (this.listView.GetCount() > 0) {
      this.listView.Modify(focusedRowNumber, "Focus Select")
      this.keywordEdit.value := this.listView.GetText(focusedRowNumber)
      ; argStr := this.listView.GetText(focusedRowNumber, 2)
      ; if (argStr) {
      ;   this.keywordEdit.value := this.keywordEdit.value .  " " . argStr
      ; }
    }
    this.keywordEdit.Focus()
  }
}