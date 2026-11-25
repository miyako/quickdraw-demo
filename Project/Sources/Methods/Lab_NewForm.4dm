#DECLARE() : Object

var $form : Object
$form:=New object

$form.lab:=cs.Lab.new()

// Object-based dropdowns: values/index/currentValue
$form.sample:=New object("values"; New collection(); "index"; 0; "currentValue"; "")
$form.container:=New object("values"; New collection("auto"; "raw"; "file"; "resource-fork"; "macbinary"; "appledouble"; "applesingle"); "index"; 0; "currentValue"; "auto")
$form.format:=New object("values"; New collection("png"; "svg"; "pdf"); "index"; 0; "currentValue"; "png")
$form.fidelity:=New object("values"; New collection("strict"; "approximate"); "index"; 0; "currentValue"; "strict")
$form.vector:=New object("values"; New collection("reject"; "preserve"; "raster"); "index"; 1; "currentValue"; "preserve")
$form.printer:=New object("values"; New collection("ignore"; "apple-portable"); "index"; 0; "currentValue"; "ignore")

$form.dataFork:=False
$form.resourceId:=""
$form.fontMap:=False
$form.width:=""
$form.height:=""
$form.dpi:=""
$form.maxPixels:=""
$form.background:=""
$form.highlight:=""

$form.sampleHint:="poster.pict needs approximate fidelity. text.pict needs the explicit NFNT map. drawing.rsrc holds PICT 128/129 and NFNT 7. broken.pict is a one-byte malformed file."
$form.help:="1. Pick a sample.\n2. Inspect shows the PICT version, frame and top-level opcodes.\n3. Convert writes Output/lab-output.* and refreshes the preview.\n\nThe preview is always approximate PNG; the requested output keeps the selected fidelity and policy."
$form.optionsHint:="Blank numeric fields are omitted, so CLI defaults apply. vector-policy applies only to SVG/PDF."
$form.expIntro:="The component never retries automatically. Each experiment demonstrates one boundary and keeps the exact CLI evidence."
$form.expHint:="failureKind: argument (no launch), asset (hash/version), process (timeout/launch), protocol (bad envelope), converter (valid nonzero exit)."

$form.customFile:=""
$form.preview:=Null
$form.previewInfo:="No preview yet."
$form.inspect:=""
$form.engine:=""
$form.status:="Starting…"
$form.json:=""
$form.rows:=New collection()

return $form
