class ClassExeFile {
  __New(iconNumber, fileName, score, fileFullPath) {
    this.argStr := "" ; dummy for ClassExeFileHistory
    this.executedAt := "-1" ; dummy for ClassExeFileHistory

    this.iconNumber := iconNumber
    this.fileName := fileName
    this.score := score
    this.fileFullPath := FileFullPath

    SplitPath fileFullPath, &name, &dir, &ext, &nameNoExt, &drive
    this.nameNoExt := nameNoExt
    this.ext := ext
  }

  AddScore(value) {
    this.score := (this.score + value)
  }

  Run(argStr := "") {
    Run(this.FileFullPath . " " . argStr)
  }

  Properties() {
    Run("properties " . this.fileFullPath)
  }
}