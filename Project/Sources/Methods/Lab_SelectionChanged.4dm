//%attributes = {"invisible":true}
// Container, data-fork or resource-ID change: the picked picture changes, so
// both the inspection and the preview must follow.
#DECLARE()

Lab_Inspect

var $input : 4D.File
$input:=Lab_InputFile
Lab_Preview($input; Form.lab.convertOptions(Form); Null)

var $ignored : Collection
$ignored:=Form.lab.invalidFields(Form)
If ($ignored.length>0)
	Form.status:=Form.status+" · ignored invalid: "+$ignored.join(", ")
End if
