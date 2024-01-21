class ClassExeFileHistory {
  __New(exeFile, argStr) {
    this.exeFile := exeFile
    this.argStr := argStr
  }

  __get(prop) {
    if (prop = "exeFile")
      return this.exeFile
    else
      return this.exeFile[prop]
  }
}