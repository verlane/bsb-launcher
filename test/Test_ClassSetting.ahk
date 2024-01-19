#include "..\Lib\String.ahk"
#include "..\Lib\Map.ahk"
#include "..\src\ClassSetting.ahk"

class ClassSettingTestSuite {
    static Fail() {
        throw Error()
    }

    Test_Set() {
        setting := ClassSetting(A_Temp . "\settings.json")
        mapObj := setting.settings

        setting.Set("a", 1)
        DUnit.Equal(mapObj["a"], 1)

        setting.Set("b", "c", 2)
        DUnit.Equal(mapObj["b"]["c"], 2)

        setting.Set("d", "e", "f", 3)
        DUnit.Equal(mapObj["d"]["e"]["f"], 3)

        DUnit.Equal(mapObj["g"], "")
    }

    Test_Get() {
        setting := ClassSetting(A_Temp . "\settings.json")
        mapObj := setting.settings

        setting.Set("a", 1)
        DUnit.Equal(setting.Get("a"), 1)

        setting.Set("b", "c", 2)
        DUnit.Equal(setting.Get("b", "c"), 2)

        setting.Set("d", "e", "f", 3)
        DUnit.Equal(setting.Get("d", "e", "f"), 3)

        DUnit.Equal(setting.Get("g"), "")
    }

    Test_Delete() {
        setting := ClassSetting(A_Temp . "\settings.json")
        mapObj := setting.settings

        setting.Set("a", 1)
        DUnit.Equal(setting.Get("a"), 1)

        setting.Delete("a")
        DUnit.Equal(setting.Get("a"), "")

        setting.Set("b", "c", 2)
        DUnit.Equal(setting.Get("b", "c"), 2)

        setting.Delete("b", "c")
        DUnit.Equal(setting.Get("b", "c"), "")
    }
}