class ClassLauncher {
  static LIST_VIEW_HEADER := ["Name", "No", "Ext", "Score", "ExecutedAt", "FileFullPath"]
  static LIST_VIEW_FILE_FULL_PATH_INDEX := 6

  static ToIntOrZero(anyValue) { ; TODO
    try {
      return Integer(anyValue)
    } catch {
      return 0
    }
  }

  __New(setting) {
    this.exeFiles := []
    this.exeFilesMap := Map()
    this.exeFileHistories := []
    this.exeFileHistoriesMap := Map()

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

    this.listView := this.gui.Add("ListView", "x6 y64 h490 w606 +Grid -Hdr", ClassLauncher.LIST_VIEW_HEADER)
    this.listView.SetFont("s12", "Segoe UI")

    ; Create an ImageList so that the ListView can display some icons:
    this.imageListID1 := IL_Create(10)
    this.ImageListID2 := IL_Create(10, 10, true)  ; A list of large icons to go with the small ones.

    ; Attach the ImageLists to the ListView so that it can later display the icons:
    this.listView.SetImageList(this.imageListID1)
    this.listView.SetImageList(this.imageListID2)

    ; Apply control events:
    this.listView.OnEvent("DoubleClick", ObjBindMethod(this, "RunFile"))
    this.listView.OnEvent("ContextMenu", ObjBindMethod(this, "ShowContextMenu"))

    ; Create a popup menu to be used as the context menu:
    this.contextMenu := Menu()
    this.contextMenu.Add("Open", ObjBindMethod(this, "RunFile"))
    this.contextMenu.Add("Properties", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add()
    this.contextMenu.Add("+5 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add("+1 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add("-1 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Add("-5 Score", ObjBindMethod(this, "ContextMenuEvent"))
    this.contextMenu.Default := "Open"  ; Make "Open" a bold font to indicate that double-click does the same thing.
    this.Show()
  }

  GetWindowTitle() {
    return this.gui.Title
  }

  Show() {
    this.gui.Show("w620 h562")
    this.keywordEdit.Focus()
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
    focusedRowNumber := this.listView.GetNext(0, "F")
    fileFullPath := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX)
    try {
      this.Hide()
      exeFile := this.exeFilesMap[fileFullPath]
      exeFile.Run()
      if (!this.exeFileHistoriesMap.Has(fileFullPath)) {
        this.exeFileHistories.InsertAt(1, exeFile)
        this.exeFileHistories := this.exeFileHistories.Sort("N R", "executedAt")
        this.exeFileHistoriesMap[fileFullPath] := exeFile
      }
      this.setting.Set("exeFileHistories", this.exeFileHistories.Slice(1, 18))
      this.setting.Save()
    } catch Error as err {
      MsgBox("Could not open " . fileFullPath . ".`nSpecifically: " . err.Message)
    }
  }

  ; In response to right-click or Apps key.
  ShowContextMenu(listView, item, isRightClick, x, y) {
    ; Show the menu at the provided coordinates, X and Y.  These should be used
    ; because they provide correct coordinates even if the user pressed the Apps key:
    this.contextMenu.Show(x, y)
  }

  ; The user selected "Open" or "Properties" in the context menu.
  ContextMenuEvent(itemName, *) {
    ; For simplicitly, operate upon only the focused row rather than all selected rows:
    focusedRowNumber := this.listView.GetNext(0, "F")  ; Find the focused row.
    if not focusedRowNumber  ; No row is focused.
      return
    fileFullPath := this.listView.GetText(focusedRowNumber, ClassLauncher.LIST_VIEW_FILE_FULL_PATH_INDEX)  ; Get the text of the second field.
    try {
      exeFile := this.exeFilesMap[fileFullPath]
      if (RegExMatch(itemName, "i)^([`+`-][0-9]+) Score$", &SubPat)) { ; User selected "Open" from the context menu.
        exeFile.AddScore(SubPat[1])
        this.FilterExeFiles(this.keywordEdit.value)
        baseScore := ClassLauncher.ToIntOrZero(this.setting.Get("exeFiles", fileFullPath, "additionalScore"))
        this.setting.Set("exeFiles", fileFullPath, "additionalScore", baseScore + Integer(SubPat[1]))
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
      if not fileExt ~= "i)\A(EXE|BAT|LNK|AHK)\z"
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
      exeFile := ClassExeFile(iconNumber, A_LoopFileName, score, A_LoopFileFullPath)
      this.exeFiles.Push(exeFile)
      this.exeFilesMap[A_LoopFileFullPath] := exeFile
    }
    this.exeFiles := this.exeFiles.Sort("N R", "Score")
  }

  LoadExeFileHistories() {
    exeFileHistories := this.setting.Get("exeFileHistories")
    if (!exeFileHistories) {
      return
    }

    for exeFileHistory in exeFileHistories {
      if (this.exeFilesMap.Has(exeFileHistory["fileFullPath"])) {
        exeFile := this.exeFilesMap[exeFileHistory["fileFullPath"]]
        exeFile.executedAt := exeFileHistory["executedAt"]
        this.exeFileHistories.Push(exeFile)
        this.exeFileHistoriesMap[exeFile.fileFullPath] := exeFile
      }
    }
  }

  AddExeFileToListView(targetExeFiles, needleKeyword := "") {
    Loop (targetExeFiles.Length) {
      exeFile := targetExeFiles[A_Index]
      addIt := false
      ; Create the new row in the ListView and assign it the icon number determined above:
      if (RegExMatch(needleKeyword, "i)^([a-z]+) ", &SubPat)) {
        if (InStr(exeFile.NameNoExt, SubPat[1]) && InStr(exeFile.Ext, "ahk")) {
          addIt := true
        }
      } else if (!needleKeyword || InStr(exeFile.NameNoExt, needleKeyword)) {
        addIt := true
      }
      if (addIt) {
        this.listView.Add("Icon" . exeFile.iconNumber, exeFile.nameNoExt, "99", exeFile.ext, exeFile.score, exeFile.executedAt, exeFile.fileFullPath)
      }
      if (this.listView.GetCount() > 18) {
        break
      }
    }
  }

  FilterExeFiles(needleKeyword := "") {
    this.listView.Delete()

    try {
      if (StrLen(needleKeyword) > 1) {
        result := eval(needleKeyword)
        this.listView.Add(, result)
        return
      }
    } catch {
    }

    ; Gather a list of file names from the selected folder and append them to the ListView:
    this.listView.Opt("-Redraw")  ; Improve performance by disabling redrawing during load.
    if (needleKeyword == "" && this.exeFileHistories.Length > 0) {
      this.AddExeFileToListView(this.exeFileHistories, needleKeyword)
    } else {
      this.AddExeFileToListView(this.exeFiles, needleKeyword)
    }

    this.listView.Opt("+Redraw -Hdr")
    this.listView.ModifyCol(1, "470 Sort")
    this.listView.ModifyCol(2, "30 Center")
    this.listView.ModifyCol(3, "40")
    this.listView.ModifyCol(4, "60 Integer SortDesc") ; sort by score
    this.listView.ModifyCol(5, "0 SortDesc") ; sort by executedAt
    this.listView.ModifyCol(6, "0")

    keys := "abcdefghijklmnopqrstuvwxyz"
    Loop this.listView.GetCount() {
      if (A_Index > 9) {
        this.listView.Modify(A_Index, "", , keys[A_Index - 9])
      } else {
        this.listView.Modify(A_Index, "", , A_Index)
      }
    }

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
    if (thisHotkey == "Up") {
      focusedRowNumber := Max(focusedRowNumber - 1, 1)
    } else if (thisHotkey == "Down") {
      focusedRowNumber := Min(focusedRowNumber + 1, this.listView.GetCount())
    }
    this.listView.Modify(0, "-Select")
    if (this.listView.GetCount() > 0) {
      this.listView.Modify(focusedRowNumber, "Focus Select")
      this.keywordEdit.value := this.listView.GetText(focusedRowNumber)
    }
    this.keywordEdit.Focus()
  }
}