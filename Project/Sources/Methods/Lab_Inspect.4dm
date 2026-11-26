//%attributes = {"invisible":true}
// Inspect the current input with the current container/selection options.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $options : Object
$options:=Form.lab.inputOptions(Form; True)

var $result : Object
$result:=Form.lab.inspect($input; $options)

var $rows : Collection
$rows:=New collection()

If (Bool($result.ok))
	var $inspection : Object
	$inspection:=$result.value.inspection
	var $frame : Object
	$frame:=$inspection.frame

	$rows.push(New object("kind";"container";"detail";String($inspection.container);"extra";"source offset "+String($inspection.source_offset)))
	$rows.push(New object("kind";"PICT version";"detail";String($inspection.pict_version);"extra";"consumed "+String($inspection.consumed_bytes)+" bytes"))
	$rows.push(New object("kind";"frame";"detail";"("+String($frame.left)+", "+String($frame.top)+") → ("+String($frame.right)+", "+String($frame.bottom)+")";"extra";String($frame.right-$frame.left)+" × "+String($frame.bottom-$frame.top)))
	var $resource : Text
	$resource:="none (bare PICT)"
	If (Value type($inspection.resource_id)=Is real)
		$resource:=String($inspection.resource_id)
	End if
	var $dpi : Text
	$dpi:="not recorded"
	If (Value type($inspection.resolution_dpi)=Is real)
		$dpi:=String($inspection.resolution_dpi)
	End if
	$rows.push(New object("kind";"resource";"detail";$resource;"extra";"resolution "+$dpi+" dpi"))

	var $operations : Collection
	$operations:=$inspection.operations
	var $ops : Text
	$ops:=""
	var $operation : Object
	var $opCount : Integer
	$opCount:=$operations.length
	var $n : Integer
	$n:=0
	For each ($operation; $operations)
		$n:=$n+1
		If ($n<=8)
			If ($n>1)
				$ops:=$ops+" · "
			End if
			$ops:=$ops+String($operation.kind)+" "+Form.lab.opcodeHex($operation.opcode)
		End if
	End for each
	If ($opCount>8)
		$ops:=$ops+" …"
	End if
	$rows.push(New object("kind";"operations";"detail";String($operations.length)+" top-level";"extra";$ops))

	var $diagnostics : Variant
	var $diagnostic : Object
	$diagnostics:=$inspection.diagnostics
	If (Value type($diagnostics)=Is collection)
		For each ($diagnostic; $diagnostics)
			$rows.push(New object("kind";"diagnostic";"detail";String($diagnostic.code);"extra";String($diagnostic.message)))
		End for each
	End if

	Form.inspect:="PICT v"+String($inspection.pict_version)+" · "+String($inspection.container)+" · "+String($operations.length)+" operations · "+String($inspection.consumed_bytes)+" bytes consumed"
	Form.status:="Inspected "+$input.fullName
Else
	$rows.push(New object("kind";"result";"detail";"inspect failed";"extra";String($result.failureKind)))
	If (Value type($result.error)=Is object)
		$rows.push(New object("kind";"error";"detail";String($result.error.code);"extra";String($result.error.message)))
		If (Value type($result.error.offset)=Is real)
			$rows.push(New object("kind";"location";"detail";"offset "+String($result.error.offset);"extra";"opcode "+String($result.error.opcode)))
		End if
	End if
	Form.inspect:="Inspection failed — "+Form.lab.failureText($result)
	Form.status:="Inspect failed — "+Form.lab.failureText($result)
	Form.preview:=Null
	Form.previewInfo:="No preview — the input could not be inspected."
End if

Form.rows:=$rows
Form.json:=JSON Stringify($result; *)
