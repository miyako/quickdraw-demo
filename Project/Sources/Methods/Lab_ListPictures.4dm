//%attributes = {"invisible":true}
// Enumerate PICT resources in the current container.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $result : Object
$result:=Form.lab.listPictures($input; Form.lab.inputOptions(Form; False))

var $rows : Collection
$rows:=New collection()

If (Bool($result.ok))
	var $inventory : Object
	$inventory:=$result.value.inventory
	$rows.push(New object("kind";"inventory";"detail";String($inventory.container);"extra";String($inventory.pictures.length)+" PICT resources"))
	var $entry : Object
	For each ($entry; $inventory.pictures)
		var $name : Text
		$name:=String($entry.name_hex)
		If ($name="")
			$name:="(unnamed)"
		End if
		$rows.push(New object("kind";"PICT "+String($entry.resource_id);"detail";$name;"extra";String($entry.length)+" B @ offset "+String($entry.offset)+" · "+String($entry.source)))
	End for each
	Form.status:="Listed "+String($inventory.pictures.length)+" PICT resources in "+$input.name
Else
	$rows.push(New object("kind";"result";"detail";"list-pictures — failed";"extra";String($result.failureKind)))
	If (Value type($result.error)=Is object)
		$rows.push(New object("kind";"error";"detail";String($result.error.code);"extra";String($result.error.message)))
	End if
	Form.status:="list-pictures — "+Form.lab.failureText($result)
End if

Form.rows:=$rows
Form.json:=JSON Stringify($result; *)
