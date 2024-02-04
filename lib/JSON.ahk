; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=100197
class JSON {
    static __New() {
        this.DefineProp('true', { value: 1 })
        this.DefineProp('false', { value: 0 })
        this.DefineProp('null', { value: '' })
    }
    static parse(str) => Map() | Array()
    static stringify(obj, space := 0) => ''
}