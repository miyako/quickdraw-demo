//%attributes = {"invisible":true}
// Null options prove the CLI defaults: strict PNG, white background, 72 dpi.
// The sample's own selection (resource ID, font map) is not an option to reset:
// without it drawing.rsrc is ambiguous and text.pict has no font binding.
#DECLARE()

Form.format.currentValue:="png"
Form.format.index:=0
Form.fidelity.currentValue:="strict"
Form.fidelity.index:=0
Form.vector.currentValue:="preserve"
Form.vector.index:=1
Form.printer.currentValue:="ignore"
Form.printer.index:=0
Form.container.currentValue:="auto"
Form.container.index:=0
Form.width:=""
Form.height:=""
Form.dpi:=""
Form.maxPixels:=""
Form.background:=""
Form.highlight:=""
Form.dataFork:=False

var $defaults : Object
$defaults:=Form.lab.sampleDefaults(Form.lab.choice(Form.sample))
If (Form.customFile#"")
	$defaults:=Form.lab.sampleDefaults("")
End if
Form.resourceId:=$defaults.resourceId
Form.fontMap:=$defaults.fontMap

Lab_Convert
Form.status:="Options reset to CLI defaults · "+Form.status
