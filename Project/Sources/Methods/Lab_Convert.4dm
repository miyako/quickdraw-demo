//%attributes = {"invisible":true}
// Convert the current input with the visible options, then refresh preview.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $options : Object
$options:=Form.lab.convertOptions(Form)
var $format : Text
$format:=String($options.format)

var $output : 4D.File
$output:=Form.lab.outputFolder.file("lab-output."+$format)
If ($output.exists)
	var $deleted : Boolean
	$deleted:=$output.delete()
End if

var $result : Object
$result:=Form.lab.convert($input; $output; $options)

var $rows : Collection
$rows:=New collection()

If (Bool($result.ok))
	var $value : Object
	$value:=$result.value
	$rows.push(New object("kind";"result";"detail";"converted";"extra";"exit 0 · sha256 verified below"))
	$rows.push(New object("kind";"output";"detail";String($value.output);"extra";String($value.format)+" · "+String($value.width)+"×"+String($value.height)+" · "+String($value.bytes)+" B · "+String($value.dpi)+" dpi"))
	$rows.push(New object("kind";"profiles";"detail";String($value.raster_profile);"extra";"vector "+String($value.vector_profile)+" · outline "+String($value.outline_profile)))

	var $expected : Text
	$expected:=String($value.sha256)
	var $actual : Text
	$actual:=Form.lab.digest($output)
	If ($expected=$actual)
		$rows.push(New object("kind";"sha256";"detail";"matches file bytes";"extra";Substring($expected; 1; 24)+"…"))
	Else
		$rows.push(New object("kind";"sha256";"detail";"MISMATCH";"extra";Substring($expected; 1; 24)+"… vs "+Substring($actual; 1; 24)+"…"))
	End if

	var $diagnostics : Variant
	var $diagnostic : Object
	$diagnostics:=$value.diagnostics
	If (Value type($diagnostics)=Is collection)
		For each ($diagnostic; $diagnostics)
			$rows.push(New object("kind";"diagnostic";"detail";String($diagnostic.code);"extra";String($diagnostic.message)))
		End for each
	End if

	Form.status:="Converted "+$input.fullName+" → "+$output.fullName+" ("+String($value.bytes)+" B)"
	var $ignored : Collection
	$ignored:=Form.lab.invalidFields(Form)
	If ($ignored.length>0)
		Form.status:=Form.status+" · ignored invalid: "+$ignored.join(", ")
	End if
	Form.json:=JSON Stringify($value; *)
Else
	$rows.push(New object("kind";"result";"detail";"conversion rejected";"extra";String($result.failureKind)))
	If (Value type($result.error)=Is object)
		$rows.push(New object("kind";"error";"detail";String($result.error.code);"extra";String($result.error.message)))
		If (Value type($result.error.offset)=Is real)
			$rows.push(New object("kind";"location";"detail";"offset "+String($result.error.offset);"extra";"opcode "+String($result.error.opcode)))
		End if
	End if
	Form.status:="Convert failed — "+Form.lab.failureText($result)
	Form.json:=JSON Stringify($result; *)
End if

Lab_Preview($input; $options; $result)
Form.rows:=$rows
