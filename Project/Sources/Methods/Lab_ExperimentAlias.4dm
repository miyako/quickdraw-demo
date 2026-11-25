// Alias experiment: input path as output path with overwrite enabled.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $options : Object
$options:=Form.lab.convertOptions(Form)
$options["format"]:="png"
$options["overwrite"]:=True

var $digestBefore : Text
$digestBefore:=Form.lab.digest($input)

var $result : Object
$result:=Form.lab.convert($input; $input; $options)
Lab_Report($result; "input == output with overwrite")

var $digestAfter : Text
$digestAfter:=Form.lab.digest($input)
var $rows : Collection
$rows:=Form.rows
$rows.unshift(New object("kind";"source unchanged";"detail";String($digestBefore=$digestAfter);"extra";Substring($digestBefore; 1; 24)+"…"))
$rows.unshift(New object("kind";"experiment";"detail";"source/output alias";"extra";"the CLI owns alias safeguards when a caller passes the same path"))
Form.rows:=$rows
