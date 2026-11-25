// Dropdown/input change: refresh the preview, do not write an output file.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
If ($input#Null)
	Lab_Preview($input; Form.lab.convertOptions(Form); Null)
	Form.status:="Options changed — preview refreshed. Press Convert to write an output file."
End if
