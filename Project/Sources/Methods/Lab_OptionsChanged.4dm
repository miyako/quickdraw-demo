//%attributes = {"invisible":true}
// Dropdown/input change: refresh the preview, do not write an output file.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
If ($input#Null)
	Lab_Preview($input; Form.lab.convertOptions(Form); Null)
	Form.status:="Options changed — preview refreshed. Press Convert to write an output file."
	var $ignored : Collection
	$ignored:=Form.lab.invalidFields(Form)
	If ($ignored.length>0)
		Form.status:=Form.status+" Ignored invalid: "+$ignored.join(", ")+" (CLI default used)."
	End if
End if
