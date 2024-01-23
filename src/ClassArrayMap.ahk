class ClassArrayMap {
  __New(objects := [], objectsMap := Map()) {
    this.objects := objects
    this.objectsMap := objectsMap
  }

  Push(mapKey, obj) {
    if (this.objectsMap.Has(mapKey)) {
      storedObj := this.objectsMap[mapKey]
      this.objects := this.objects.Filter((currentObj) => (
        storedObj != currentObj
      ))
    }
    this.objectsMap[mapKey] := obj
    this.objects.Push(obj)
  }

  Sort(optionsOrCallback := "N", key?) {
    this.objects.Sort(optionsOrCallback, key)
    return this.objects
  }

  Slice(start := 1, end := 0, step := 1) {
    return this.objects.Slice(start, end, step)
  }

  Has(mapKey) {
    return this.objectsMap.has(mapKey)
  }

  Get(mapKey) {
    return this.objectsMap[mapKey]
  }

  GetAll() {
    return this.objects
  }

  Delete(mapKey) {
    if (this.objectsMap.Has(mapKey)) {
      storedObj := this.objectsMap[mapKey]
      this.objectsMap.Delete(mapKey)
      this.objects := this.objects.Filter((currentObj) => (
        storedObj != currentObj
      ))
      return storedObj
    }
  }

  Length() {
    return this.objects.Length
  }
}