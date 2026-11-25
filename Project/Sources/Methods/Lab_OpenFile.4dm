// Pick any file from disk (PICT, resource fork, MacBinary, AppleDouble…).
#DECLARE()

ARRAY TEXT($paths; 0)
var $selected : Variant
$selected:=Select document(""; ""; "Choose a picture, resource fork or MacBinary file"; 0; $paths)

If ((Value type($selected)=Is real) && ($selected>0))
	Form.customFile:=$paths{1}
	Form.sample.currentValue:=""
	Form.sample.index:=-1
	Form.resourceId:=""
	Form.fontMap:=False

	Lab_Inspect
	var $input : 4D.File
	$input:=Lab_InputFile
	Lab_Preview($input; Form.lab.convertOptions(Form); Null)
	Form.status:="Opened "+Form.customFile
End if
