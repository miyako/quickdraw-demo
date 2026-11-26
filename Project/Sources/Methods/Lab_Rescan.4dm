//%attributes = {"invisible":true}
// Re-read /RESOURCES/Samples (useful after regenerating fixtures).
// A file chosen with Open… is not a sample: rescanning must not discard it.
#DECLARE()

// Resolve the current pick from the old list BEFORE replacing it: the index
// is only meaningful against the values it was chosen from.
var $current : Text
$current:=Form.lab.choice(Form.sample)
var $names : Collection
$names:=Form.lab.samples()
Form.sample.values:=$names

If (Form.customFile#"")
	Form.status:="Rescanned "+String($names.length)+" samples · kept "+Form.customFile
Else
	If (($current#"") && ($names.indexOf($current)>=0))
		Form.sample.currentValue:=$current
		Form.sample.index:=$names.indexOf($current)
	Else
		If ($names.length>0)
			Form.sample.currentValue:=String($names[0])
			Form.sample.index:=0
		Else
			Form.sample.currentValue:=""
			Form.sample.index:=-1
		End if
	End if
	Lab_SelectSample
End if
