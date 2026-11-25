// On Load: populate samples, engine facts and the first inspection.
#DECLARE()

Form.sample.values:=Form.lab.samples()

var $default : Text
$default:="poster.pict"
If (Form.sample.values.indexOf($default)<0)
	If (Form.sample.values.length>0)
		$default:=String(Form.sample.values[0])
	Else
		$default:=""
	End if
End if
Form.sample.currentValue:=$default
Form.sample.index:=Form.sample.values.indexOf($default)

// Both calls return the full process envelope; the payload is in .value.
var $versionReply : Object
$versionReply:=Form.lab.version()
var $version : Object
$version:=New object("protocol"; 0; "version"; "unknown")
If (Bool($versionReply.ok))
	$version:=$versionReply.value
End if

var $capsReply : Object
$capsReply:=Form.lab.capabilities()
var $caps : Object
$caps:=New object("formats"; New collection(); "vector_policies"; New collection(); "containers"; New collection(); "approximate_only"; New collection(); "warnings"; New collection(); "fidelity"; New object("strict"; False); "default_limits"; New object("max_pixels"; 0; "max_operations"; 0))
If (Bool($capsReply.ok))
	$caps:=$capsReply.value
End if

var $engine : Text
$engine:="quickdraw CLI "+String($version.version)+" · protocol "+String($version.protocol)+"\n"
$engine:=$engine+"target "+Form.lab.target+" · component 0.1.3\n"
$engine:=$engine+"formats "+$caps.formats.join(", ")+" · vectors "+$caps.vector_policies.join("/")+"\n"
$engine:=$engine+"containers "+$caps.containers.join(", ")+"\n"
$engine:=$engine+"strict: "+String($caps.fidelity.strict)+"\n"
$engine:=$engine+"approximate-only categories: "+String($caps.approximate_only.length)+"\n"
$engine:=$engine+"defaults: "+String($caps.default_limits.max_pixels)+" px · "+String($caps.default_limits.max_operations)+" ops"
Form.engine:=$engine

var $rows : Collection
$rows:=New collection()
$rows.push(New object("kind";"quickdraw";"detail";"CLI "+String($version.version)+" · protocol "+String($version.protocol);"extra";"component 0.1.3"))
$rows.push(New object("kind";"strict";"detail";String($caps.fidelity.strict);"extra";"not a pixel-identity guarantee"))
$rows.push(New object("kind";"retained on success";"detail";String($caps.warnings);"extra";"diagnostics are mandatory evidence"))
$rows.push(New object("kind";"exit codes";"detail";"2 args · 3 io · 4 malformed · 5 unsupported · 6 limit · 7 encoding";"extra";"no automatic retry"))
Form.rows:=$rows
Form.json:=JSON Stringify($caps; *)
Form.status:="Ready — select a sample, then Inspect or Convert."

If ($default#"")
	Lab_SelectSample
End if
