class ClassSetting {
  __New(fileFullPath) {
    this.fileFullPath := fileFullPath
    this.settings := this.Load()
  }

  Load() {
    if FileExist(this.fileFullPath) {
      return JSON.parse(FileRead(this.fileFullPath))
    }
    return this.NewMap()
  }

  Save() {
    if FileExist(this.fileFullPath) {
      FileDelete this.fileFullPath
    }
    FileAppend JSON.stringify(this.settings), this.fileFullPath
  }

  Get(mapKeys*) {
    nextValue := this.settings
    for index, mapKey in mapKeys {
      if (nextValue is Map) {
        nextValue.Default := ""
      }

      if (mapKeys.Length == index) { ; last item
        return nextValue[mapKey]
      }

      nextValue := nextValue[mapKey]
      if not nextValue is Map and index < mapKeys.Length {
        return ""
      } else if not nextValue is Map {
        return nextValue
      }
    }
  }

  Set(mapKeysAndValue*) {
    if (mapKeysAndValue.Length < 2) {
      throw ValueError("Parameter #1 invalid", -1, mapKeysAndValue)
    }

    mapKeys := mapKeysAndValue.Slice(1, mapKeysAndValue.Length - 1)
    valueToSet := mapKeysAndValue.Slice(mapKeysAndValue.Length, mapKeysAndValue.Length)[1]

    if (mapKeysAndValue.Length == 2) {
      this.settings[mapKeys[1]] := valueToSet
      return
    }

    nextMap := this.settings
    for index, mapKey in mapKeys {
      tmpMap := nextMap.Get(mapKey, this.NewMap())
      nextMap[mapKey] := tmpMap

      if (mapKeys.Length - 1 == index) {
        nextMapKey := mapKeys[index + 1]
        tmpMap[nextMapKey] := valueToSet
        break
      } else {
        nextMap := tmpMap
      }
    }
  }

  Delete(mapKeys*) {
    if (mapKeys.Length < 2) {
      this.settings.Delete(mapKeys[1])
      return
    }
    nextMap := this.settings
    for index, mapKey in (mapKeys.Slice(1, mapKeys.Length - 1)) {
      nextMap := nextMap.Get(mapKey, this.NewMap())
    }
    nextMap.Delete(mapKeys[mapKeys.Length])
  }

  NewMap() {
    mapObj := Map()
    mapObj.Default := ""
    return mapObj
  }
}