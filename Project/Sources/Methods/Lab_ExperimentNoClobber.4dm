//%attributes = {"invisible":true}
// Provenance experiment: write twice without --overwrite.
#DECLARE()

var $input : 4D.File
$input:=Lab_InputFile
var $options : Object
$options:=Form.lab.convertOptions(Form)
// The experiment is about the output file, not about coverage: strict mode
// rejects poster.pict before anything is written, so the second call would
// fail with "unsupported" and never reach the existing-output check.
$options["fidelity"]:="approximate"
var $format : Text
$format:=String($options.format)
var $output : 4D.File
$output:=Form.lab.outputFolder.file("lab-noclobber."+$format)
If ($output.exists)
	var $deleted : Boolean
	$deleted:=$output.delete()
End if

var $first : Object
$first:=Form.lab.convert($input; $output; $options)
var $second : Object
$second:=Form.lab.convert($input; $output; $options)

Lab_Report($second; "Second write without overwrite")
var $rows : Collection
$rows:=Form.rows
$rows.unshift(New object("kind";"first write";"detail";"ok: "+String($first.ok);"extra";"exit "+String($first.exitCode)+" · "+String($first.failureKind)))
$rows.unshift(New object("kind";"experiment";"detail";"no-clobber";"extra";"fidelity forced to approximate so the first write succeeds; the CLI refuses to replace it unless --overwrite is passed"))
Form.rows:=$rows
