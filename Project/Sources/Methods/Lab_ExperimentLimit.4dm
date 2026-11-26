//%attributes = {"invisible":true}
// Budget experiment: max-pixels 1 must fail with resource_limit (exit 6).
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $options : Object
$options:=Form.lab.convertOptions(Form)
$options["format"]:="png"
$options["max-pixels"]:="1"

var $output : 4D.File
$output:=Form.lab.outputFolder.file("lab-limit.png")
If ($output.exists)
	var $deleted : Boolean
	$deleted:=$output.delete()
End if

var $result : Object
$result:=Form.lab.convert($input; $output; $options)
Lab_Report($result; "max-pixels = 1")
var $rows : Collection
$rows:=Form.rows
$rows.unshift(New object("kind";"experiment";"detail";"resource limit";"extra";"budgets fail closed; the CLI does not truncate or retry"))
Form.rows:=$rows

// Still show a normal preview so the artwork stays visible.
var $normal : Object
$normal:=Form.lab.convertOptions(Form)
Lab_Preview($input; $normal; $result)
