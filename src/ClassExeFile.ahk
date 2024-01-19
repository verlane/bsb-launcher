class ClassExeFile {
  __New(iconNumber, fileName, score, fileFullPath) {
    this.iconNumber := iconNumber
    this.fileName := fileName
    this.score := score
    this.fileFullPath := FileFullPath

    SplitPath fileFullPath, &name, &dir, &ext, &nameNoExt, &drive
    this.nameNoExt := nameNoExt
    this.ext := ext
    this.executedAt := "-1"
    this.updatedAt := "-1"
  }

  AddScore(value) {
    this.score := (this.score + value)
    this.updatedAt := FormatTime(A_Now, "yyyyMMddHHmmss")
  }

  Run(argStr := "") {
    this.executedAt := FormatTime(A_Now, "yyyyMMddHHmmss")
    Run(this.FileFullPath . " " . argStr)
  }

  Properties() {
    Run("properties " . this.fileFullPath)
  }
}