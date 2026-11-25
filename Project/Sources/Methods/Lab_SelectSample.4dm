// Sample dropdown / onDataChange.
#DECLARE()

Form.customFile:=""
var $name : Text
$name:=Form.lab.choice(Form.sample)

If ($name="drawing.rsrc")
	Form.resourceId:="128"
Else
	Form.resourceId:=""
End if
Form.fontMap:=($name="text.pict")

Lab_Inspect

var $input : 4D.File
$input:=Lab_InputFile
Lab_Preview($input; Form.lab.convertOptions(Form); Null)
Form.status:="Selected "+$name
