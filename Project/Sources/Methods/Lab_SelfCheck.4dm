// Headless end-to-end check. Runs the same public class the form uses and
// writes Output/selfcheck.json. Invoke with tool4d --startup-method.
#DECLARE()

var $lab : cs.Lab
$lab:=cs.Lab.new()

var $checks : Collection
$checks:=New collection()

var $report : Object
$report:=New object("when"; Timestamp; "checks"; $checks)

// 1. version handshake: the class returns the process envelope; the payload is .value.
var $versionReply : Object
$versionReply:=$lab.version()
var $version : Object
$version:=$versionReply.value
$checks.push(New object("name"; "version"; "ok"; ((Bool($versionReply.ok)) && (Value type($version.protocol)=Is real) && ($version.protocol=1) && (Value type($version.version)=Is text) && ($version.version#"")); "detail"; JSON Stringify($versionReply)))

// 2. capabilities: the CLI advertises its formats and limits.
var $capsReply : Object
$capsReply:=$lab.capabilities()
var $capabilities : Object
$capabilities:=$capsReply.value
var $formats : Collection
$formats:=$capabilities.formats
$checks.push(New object("name"; "capabilities"; "ok"; ((Bool($capsReply.ok)) && ($formats#Null) && ($formats.length>=3)); "detail"; "formats: "+String($formats.length)+", max_pixels: "+String($capabilities.default_limits.max_pixels)))

// 3. strict rejection is a feature, not a crash: exit 5 on convert.
var $poster : 4D.File
$poster:=$lab.sampleFile("poster.pict")
var $strictFile : 4D.File
$strictFile:=$lab.outputFolder.file("selfcheck-strict.png")
If ($strictFile.exists)
	var $deletedStrict : Boolean
	$deletedStrict:=$strictFile.delete()
End if
var $strict : Object
$strict:=$lab.convert($poster; $strictFile; New object("format"; "png"; "fidelity"; "strict"; "overwrite"; True))
$checks.push(New object("name"; "strict rejection"; "ok"; (Not(Bool($strict.ok))) && (String($strict.failureKind)="converter") && (Not($strictFile.exists)) && (Position("(offset 200, opcode 81)"; $lab.failureText($strict))>0); "detail"; $lab.failureText($strict)+" · exit "+String($strict.exitCode)))

// 4. the same picture is inspected; fidelity is a convert-only concern.
var $approx : Object
$approx:=$lab.inspect($poster; New object("max-pixels"; "2000000"))
$checks.push(New object("name"; "approximate inspect"; "ok"; (Bool($approx.ok)) && ($approx.value.inspection.pict_version=2); "detail"; "PICT v"+String($approx.value.inspection.pict_version)+", "+String($approx.value.inspection.operations.length)+" top-level ops"))

// 5. font resolution is explicit: text.pict needs the NFNT map at convert time.
var $textFile : 4D.File
$textFile:=$lab.sampleFile("text.pict")
var $noMapFile : 4D.File
$noMapFile:=$lab.outputFolder.file("selfcheck-nomap.png")
If ($noMapFile.exists)
	var $deletedNoMap : Boolean
	$deletedNoMap:=$noMapFile.delete()
End if
var $mapFile : 4D.File
$mapFile:=$lab.outputFolder.file("selfcheck-map.png")
If ($mapFile.exists)
	var $deletedMap : Boolean
	$deletedMap:=$mapFile.delete()
End if
var $noMap : Object
$noMap:=$lab.convert($textFile; $noMapFile; New object("format"; "png"; "fidelity"; "strict"; "overwrite"; True))
var $withMap : Object
$withMap:=$lab.convert($textFile; $mapFile; New object("format"; "png"; "fidelity"; "strict"; "overwrite"; True; "font-map"; $lab.samplesFolder.file("fonts.json")))
$checks.push(New object("name"; "explicit font map"; "ok"; (Not(Bool($noMap.ok))) && (Bool($withMap.ok)); "detail"; "without map: "+$lab.failureText($noMap)+" · with map: ok"))

// 6. resource containers: inventory PICT and NFNT resources in one file.
var $rsrc : 4D.File
$rsrc:=$lab.sampleFile("drawing.rsrc")
var $pictures : Object
$pictures:=$lab.listPictures($rsrc; New object())
var $fonts : Object
$fonts:=$lab.listFonts($rsrc; New object())
$checks.push(New object("name"; "resource inventory"; "ok"; (Bool($pictures.ok)) && (Bool($fonts.ok)) && ($pictures.value.inventory.pictures.length=2) && ($fonts.value.inventory.resources.length=1); "detail"; String($pictures.value.inventory.pictures.length)+" PICT, "+String($fonts.value.inventory.resources.length)+" NFNT"))

// 7. conversion writes a real file and never claims pixel identity.
var $png : 4D.File
$png:=$lab.outputFolder.file("selfcheck.png")
If ($png.exists)
	var $deleted : Boolean
	$deleted:=$png.delete()
End if
var $converted : Object
$converted:=$lab.convert($poster; $png; New object("format"; "png"; "fidelity"; "approximate"; "overwrite"; True))
var $bytes : Integer
$bytes:=0
If ($png.exists)
	$bytes:=$png.size
End if
$checks.push(New object("name"; "png conversion"; "ok"; (Bool($converted.ok)) && ($bytes>0); "detail"; $png.fullName+" · "+String($bytes)+" bytes · "+Substring($lab.digest($png); 1; 16)+"…"))

// 8. no-clobber: an existing output is refused instead of replaced.
var $noClobber : Object
$noClobber:=$lab.convert($poster; $png; New object("format"; "png"; "fidelity"; "approximate"))
$checks.push(New object("name"; "no-clobber"; "ok"; (Not(Bool($noClobber.ok))) && (String($noClobber.failureKind)="converter"); "detail"; $lab.failureText($noClobber)+" · exit "+String($noClobber.exitCode)))

// 9. pixel budget: exit 6 without writing partial output.
var $limited : 4D.File
$limited:=$lab.outputFolder.file("selfcheck-limit.png")
If ($limited.exists)
	var $deletedLimited : Boolean
	$deletedLimited:=$limited.delete()
End if
var $limit : Object
$limit:=$lab.convert($poster; $limited; New object("format"; "png"; "fidelity"; "approximate"; "overwrite"; True; "max-pixels"; "1"))
$checks.push(New object("name"; "pixel budget"; "ok"; (Not(Bool($limit.ok))) && (String($limit.failureKind)="converter") && (Not($limited.exists)); "detail"; $lab.failureText($limit)+" · no partial file"))

// 10. malformed input is a converter failure with offset evidence.
var $broken : 4D.File
$broken:=$lab.sampleFile("broken.pict")
var $malformed : Object
$malformed:=$lab.inspect($broken; New object())
$checks.push(New object("name"; "malformed input"; "ok"; (Not(Bool($malformed.ok))) && (String($malformed.failureKind)="converter"); "detail"; $lab.failureText($malformed)+" · exit "+String($malformed.exitCode)))

// 11. preview path is always approximate PNG, even for poster.pict.
var $preview : Object
$preview:=$lab.preview($poster; New object("fidelity"; "strict"; "format"; "svg"))
$checks.push(New object("name"; "approximate preview"; "ok"; (Bool($preview.result.ok)) && (Picture size($preview.picture)>0); "detail"; "requested strict SVG, previewed PNG"))

// 12. the form's option wiring: the same builders the buttons use, fed by the
// form model from Lab_NewForm, must produce options the CLI accepts. This is
// the path drawing.rsrc takes (container + resource-id) and the one text.pict
// takes (font map), plus the 0x-prefixed opcode label shown by Inspect.
var $model : Object
$model:=Lab_NewForm
var $defaults : Object
$defaults:=$lab.sampleDefaults("drawing.rsrc")
$model.resourceId:=$defaults.resourceId
$model.fidelity.index:=1
var $wiredInspect : Object
$wiredInspect:=$lab.inspect($rsrc; $lab.inputOptions($model; True))
var $wiredConvert : Object
var $wiredFile : 4D.File
$wiredFile:=$lab.outputFolder.file("selfcheck-wired.png")
If ($wiredFile.exists)
	var $deletedWired : Boolean
	$deletedWired:=$wiredFile.delete()
End if
var $wiredOptions : Object
$wiredOptions:=$lab.convertOptions($model)
$wiredOptions["overwrite"]:=True
$wiredConvert:=$lab.convert($rsrc; $wiredFile; $wiredOptions)
var $hexOk : Boolean
$hexOk:=($lab.opcodeHex(81)="0x0051")
var $badForm : Object
$badForm:=New object("width"; "12x"; "dpi"; "72"; "background"; "GG0000"; "resourceId"; "-3")
var $invalid : Collection
$invalid:=$lab.invalidFields($badForm)
$checks.push(New object("name"; "form option wiring"; "ok"; (Bool($wiredInspect.ok)) && (Bool($wiredConvert.ok)) && ($wiredInspect.value.inspection.resource_id=128) && ($hexOk) && ($invalid.length=2) && ($invalid.indexOf("width")>=0) && ($invalid.indexOf("background")>=0); "detail"; "drawing.rsrc via resource-id 128 · opcode 81 = "+$lab.opcodeHex(81)+" · invalid: "+$invalid.join(", ")+" · inspect: "+$lab.failureText($wiredInspect)+" · convert: "+$lab.failureText($wiredConvert)))

// 13. the sample dropdown is fed by samples(): file names with extension, only
// PICT and resource files (font.nfnt and fonts.json are not samples).
var $samples : Collection
$samples:=$lab.samples()
$checks.push(New object("name"; "sample list"; "ok"; ($samples.length=5) && ($samples.indexOf("poster.pict")>=0) && ($samples.indexOf("drawing.rsrc")>=0) && ($samples.indexOf("font.nfnt")<0) && ($lab.sampleFile($samples[0]).exists); "detail"; $samples.join(", ")))

var $passed : Integer
$passed:=0
var $check : Object
For each ($check; $checks)
	If (Bool($check.ok))
		$passed:=$passed+1
	End if
End for each
$report["passed"]:=$passed
$report["total"]:=$checks.length
$report["finished"]:=True

var $file : 4D.File
$file:=$lab.outputFolder.file("selfcheck.json")
var $written : Boolean
$written:=$file.create()
var $text : Text
$text:=JSON Stringify($report; *)
$written:=$file.setText($text)

If (Not($file.exists))
	ALERT("QuickDraw self-check could not write "+$file.platformPath)
End if
