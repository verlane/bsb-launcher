; File cache system for BSB Launcher
; Caches file information and icons to improve loading performance

class ClassFileCache {
  __New(cacheFilePath := "") {
    this.cacheFilePath := cacheFilePath ? cacheFilePath : A_ScriptDir . "\file_cache.json"
    this.iconCacheFilePath := A_ScriptDir . "\icon_cache.json"
    this.cache := Map()
    this.iconCache := Map()
    this.Load()
  }

  Load() {
    ; Load file cache
    if FileExist(this.cacheFilePath) {
      try {
        cacheJson := FileRead(this.cacheFilePath)
        cacheData := JSON.parse(cacheJson)

        if (cacheData && cacheData.Has("files")) {
          for filePath, fileInfo in cacheData["files"] {
            this.cache[filePath] := fileInfo
          }
        }
      } catch as e {
        ; Cache file corrupted, ignore and start fresh
      }
    }

    ; Load icon cache
    if FileExist(this.iconCacheFilePath) {
      try {
        iconJson := FileRead(this.iconCacheFilePath)
        iconData := JSON.parse(iconJson)

        if (iconData && iconData.Has("icons")) {
          for extId, iconNum in iconData["icons"] {
            this.iconCache[extId] := iconNum
          }
        }
      } catch as e {
        ; Icon cache corrupted, ignore
      }
    }
  }

  Save() {
    ; Save file cache
    cacheData := Map()
    cacheData["lastSaved"] := FormatTime(A_Now, "yyyyMMddHHmmss")
    cacheData["files"] := Map()

    for filePath, fileInfo in this.cache {
      cacheData["files"][filePath] := fileInfo
    }

    try {
      cacheJson := JSON.stringify(cacheData, 2)
      FileDelete(this.cacheFilePath)
      FileAppend(cacheJson, this.cacheFilePath, "UTF-8")
    } catch as e {
      ; Failed to save cache
    }

    ; Save icon cache
    iconData := Map()
    iconData["lastSaved"] := FormatTime(A_Now, "yyyyMMddHHmmss")
    iconData["icons"] := Map()

    for extId, iconNum in this.iconCache {
      iconData["icons"][extId] := iconNum
    }

    try {
      iconJson := JSON.stringify(iconData, 2)
      FileDelete(this.iconCacheFilePath)
      FileAppend(iconJson, this.iconCacheFilePath, "UTF-8")
    } catch as e {
      ; Failed to save icon cache
    }
  }

  GetFileInfo(filePath) {
    if (!this.cache.Has(filePath)) {
      return false
    }

    cachedInfo := this.cache[filePath]

    ; Check if file still exists and hasn't been modified
    if (!FileExist(filePath)) {
      this.cache.Delete(filePath)
      return false
    }

    try {
      currentModified := FileGetTime(filePath, "M")
      if (cachedInfo["modified"] != currentModified) {
        ; File has been modified, invalidate cache
        this.cache.Delete(filePath)
        return false
      }
    } catch {
      this.cache.Delete(filePath)
      return false
    }

    return cachedInfo
  }

  SetFileInfo(filePath, iconNumber, score) {
    try {
      modified := FileGetTime(filePath, "M")
      this.cache[filePath] := Map(
        "iconNumber", iconNumber,
        "score", score,
        "modified", modified
      )
    } catch {
      ; Cannot get file time, skip caching
    }
  }

  GetIconNumber(extId) {
    return this.iconCache.Has(extId) ? this.iconCache[extId] : 0
  }

  SetIconNumber(extId, iconNumber) {
    this.iconCache[extId] := iconNumber
  }

  Clear() {
    this.cache := Map()
    this.iconCache := Map()
    try {
      FileDelete(this.cacheFilePath)
      FileDelete(this.iconCacheFilePath)
    }
  }

  GetCachedFilesCount() {
    return this.cache.Count
  }

  GetCachedIconsCount() {
    return this.iconCache.Count
  }
}
