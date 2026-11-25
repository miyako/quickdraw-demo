// Enumerate NFNT/FONT/FOND resources in the current container.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $result : Object
$result:=Form.lab.listFonts($input; Form.lab.inputOptions(Form; False))

var $rows : Collection
$rows:=New collection()

If (Bool($result.ok))
	var $inventory : Object
	$inventory:=$result.value.inventory
	$rows.push(New object("kind";"inventory";"detail";String($inventory.container);"extra";String($inventory.resources.length)+" font resources"))
	For each ($entry; $inventory.resources)
		$rows.push(New object("kind";String($entry.type)+" "+String($entry.resource_id);"detail";String($entry.name_hex);"extra";String($entry.length)+" B @ offset "+String($entry.offset)))
	End for each
	Form.status:="Listed "+String($inventory.resources.length)+" font resources in "+$input.name
Else
	$rows.push(New object("kind";"result";"detail";"list-fonts — failed";"extra";String($result.failureKind)))
	If (Value type($result.error)=Is object)
		$rows.push(New object("kind";"error";"detail";String($result.error.code);"extra";String($result.error.message)))
	End if
	Form.status:="list-fonts — "+Form.lab.failureText($result)
End if

Form.rows:=$rows
Form.json:=JSON Stringify($result; *)
