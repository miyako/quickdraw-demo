// Re-read /RESOURCES/Samples (useful after regenerating fixtures).
#DECLARE()

var $current : Text
$current:=String(Form.sample.currentValue)
var $names : Collection
$names:=Form.lab.samples()
Form.sample.values:=$names

If (($current#"") && ($names.indexOf($current)>=0))
	Form.sample.currentValue:=$current
Else
	Form.customFile:=""
	If ($names.length>0)
		Form.sample.currentValue:=String($names[0])
		Form.sample.index:=0
	Else
		Form.sample.currentValue:=""
		Form.sample.index:=-1
	End if
End if

Lab_SelectSample
