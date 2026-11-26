//%attributes = {"invisible":true}
// Sample dropdown / onDataChange.
#DECLARE()

Form.customFile:=""
var $name : Text
$name:=Form.lab.choice(Form.sample)

// A new sample starts from a clean selection: the previous sample's container,
// data-fork flag or resource ID would otherwise leak into it.
var $defaults : Object
$defaults:=Form.lab.sampleDefaults($name)
Form.resourceId:=$defaults.resourceId
Form.fontMap:=$defaults.fontMap
Form.dataFork:=False
Form.container.currentValue:="auto"
Form.container.index:=0

Lab_Inspect

var $input : 4D.File
$input:=Lab_InputFile
Lab_Preview($input; Form.lab.convertOptions(Form); Null)
Form.status:="Selected "+$name
