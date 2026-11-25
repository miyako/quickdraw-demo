// Malformed container experiment: broken.pict is a one-byte file.
#DECLARE()

var $input : 4D.File
$input:=Form.lab.samplesFolder.file("broken.pict")
var $result : Object
$result:=Form.lab.inspect($input; New object("container"; "auto"))

Lab_Report($result; "inspect broken.pict")
var $rows : Collection
$rows:=Form.rows
$rows.unshift(New object("kind";"experiment";"detail";"malformed input";"extra";"exit 4 · invalid_arguments=2, io=3, malformed=4, unsupported=5, limit=6, encoding=7"))
Form.rows:=$rows

Form.preview:=Null
Form.previewInfo:="No preview — the container signature is malformed."
