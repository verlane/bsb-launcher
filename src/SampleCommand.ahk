; Help: Google Search
; Help: e.g. 'g' or 'g [keyword]'
#Include DefaultFunctions.ahk

if (arg0Original) {
  Run("https://www.google.com/search?q=" . UrlEncode(arg0Original))
} else {
  Run("taskmgr")
}