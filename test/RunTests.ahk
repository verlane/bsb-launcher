#include ..\Lib\DUnit.ahk
#include Test_String.ahk
#include Test_Array.ahk
#include Test_Misc.ahk
#include Test_Map.ahk
#include Test_ClassSetting.ahk

; DUnit("C", StringTestSuite, ArrayTestSuite, MapTestSuite, MiscTestSuite)
DUnit("C", ClassSettingTestSuite)