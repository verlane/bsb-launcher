class ClassExeFileHistory {
  __New(exeFile, argStr) {
    this.exeFile := exeFile
    this.argStr := argStr
    this.executedAt := "-1"
  }

  __Get(name, params) {
    if (name = "exeFile")
      return this.exeFile
    else if (name = "executedAt")
      return this.executedAt
    else
      return this.exeFile.%name%
  }
}