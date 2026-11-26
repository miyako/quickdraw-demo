//%attributes = {"invisible":true}
// Shared result renderer for experiments: rows + raw envelope JSON.
#DECLARE($result : Object; $title : Text)

var $rows : Collection
$rows:=New collection()

If (Bool($result.ok))
	$rows.push(New object("kind";"result";"detail";$title+" — ok";"extra";"exit 0"))
	var $value : Object
	$value:=$result.value
	If (Value type($value.format)=Is text)
		$rows.push(New object("kind";"output";"detail";String($value.output);"extra";String($value.format)+" · "+String($value.width)+"×"+String($value.height)+" · "+String($value.bytes)+" B"))
	End if
	If (Value type($value.container)=Is text)
		$rows.push(New object("kind";"container";"detail";String($value.container);"extra";"pict v"+String($value.pict_version)+" · resource "+String($value.resource_id)))
	End if
	If (Value type($value.operations)=Is collection)
		$rows.push(New object("kind";"operations";"detail";String($value.operations.length)+" top-level operations";"extra";"consumed "+String($value.consumed_bytes)+" bytes"))
	End if
	If (Value type($value.inventory)=Is object)
		var $pictures : Variant
		$pictures:=$value.inventory.pictures
		If (Value type($pictures)=Is collection)
			$rows.push(New object("kind";"inventory";"detail";String($pictures.length)+" PICT resources";"extra";"container "+String($value.inventory.container)))
		End if
		$pictures:=$value.inventory.resources
		If (Value type($pictures)=Is collection)
			$rows.push(New object("kind";"inventory";"detail";String($pictures.length)+" font resources";"extra";"container "+String($value.inventory.container)))
		End if
	End if
	If (Value type($value.sha256)=Is text)
		$rows.push(New object("kind";"sha256";"detail";Substring(String($value.sha256); 1; 24)+"…";"extra";"output hash"))
	End if
	If (Value type($value.vector_profile)=Is text)
		$rows.push(New object("kind";"profile";"detail";String($value.vector_profile);"extra";"raster "+String($value.raster_profile)+" · outline "+String($value.outline_profile)))
	End if
	var $diagnostics : Variant
	var $diagnostic : Object
	$diagnostics:=$value.diagnostics
	If (Value type($diagnostics)=Is collection)
		For each ($diagnostic; $diagnostics)
			$rows.push(New object("kind";"diagnostic";"detail";String($diagnostic.code);"extra";String($diagnostic.message)))
		End for each
	End if
	Form.status:=$title+" — ok"
Else
	$rows.push(New object("kind";"result";"detail";$title+" — failed";"extra";String($result.failureKind)))
	If (Value type($result.error)=Is object)
		$rows.push(New object("kind";"error";"detail";String($result.error.code);"extra";String($result.error.message)))
		If (Value type($result.error.offset)=Is real)
			$rows.push(New object("kind";"location";"detail";"offset "+String($result.error.offset);"extra";"opcode "+String($result.error.opcode)))
		End if
	End if
	Form.status:=$title+" — "+Form.lab.failureText($result)
End if

Form.rows:=$rows
Form.json:=JSON Stringify($result; *)
