#DECLARE() : 4D.File

var $file : 4D.File
If (Form.customFile#"")
	$file:=File(Form.customFile; fk platform path)
Else
	$file:=Form.lab.sampleFile(Form.lab.choice(Form.sample))
End if
return $file
