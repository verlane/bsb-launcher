class ClassExeFile {
  __New(iconNumber, score, fileFullPath) {
    this.argStr := "" ; dummy for ClassExeFileHistory
    this.executedAt := "-1" ; dummy for ClassExeFileHistory

    this.iconNumber := iconNumber
    this.score := score
    this.fileFullPath := fileFullPath

    SplitPath fileFullPath, &name, &dir, &ext, &nameNoExt, &drive
    this.nameNoExt := nameNoExt.Replace(" ", "`r") ; for params
    this.ext := ext
  }

  AddScore(value) {
    this.score := (this.score + value)
  }

  Run(argStr := "") {
    if (InStr(this.ext, "ahk")) {
      command := A_AhkPath . " " . this.fileFullPath . " " . argStr
    } else {
      command := this.fileFullPath . " " . argStr
    }
    Run(command)
  }

  Properties() {
    Run("properties " . this.fileFullPath)
  }
}