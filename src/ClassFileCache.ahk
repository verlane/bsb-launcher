; Icon cache system for BSB Launcher
; Caches icon numbers to prevent expensive DllCall operations

class ClassFileCache {
  __New() {
    this.iconCacheFilePath := A_ScriptDir . "\icon_cache.ini"
    this.iconCache := Map()
    this.Load()
  }

  Load() {
    ; Load icon cache from INI file
    if FileExist(this.iconCacheFilePath) {
      try {
        Loop Read, this.iconCacheFilePath
        {
          line := Trim(A_LoopReadLine)
          if (line && !InStr(line, "[") && InStr(line, "=")) {
            parts := StrSplit(line, "=")
            if (parts.Length == 2) {
              extId := parts[1]
              iconNum := Integer(parts[2])
              this.iconCache[extId] := iconNum
            }
          }
        }
      } catch as e {
        ; Cache file corrupted, ignore and start fresh
      }
    }
  }

  Save() {
    ; Save icon cache to INI file
    try {
      if FileExist(this.iconCacheFilePath) {
        FileDelete(this.iconCacheFilePath)
      }

      output := "[IconCache]`n"
      output .= "; Generated: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n"

      for extId, iconNum in this.iconCache {
        output .= extId . "=" . iconNum . "`n"
      }

      FileAppend(output, this.iconCacheFilePath, "UTF-8")
    } catch as e {
      ; Failed to save cache
    }
  }

  GetIconNumber(extId) {
    return this.iconCache.Has(extId) ? this.iconCache[extId] : 0
  }

  SetIconNumber(extId, iconNumber) {
    this.iconCache[extId] := iconNumber
  }

  Clear() {
    this.iconCache := Map()
    try {
      if FileExist(this.iconCacheFilePath) {
        FileDelete(this.iconCacheFilePath)
      }
    }
  }

  GetCachedIconsCount() {
    return this.iconCache.Count
  }
}
