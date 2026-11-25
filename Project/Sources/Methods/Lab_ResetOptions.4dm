// Null options prove the CLI defaults: strict PNG, white background, 72 dpi.
#DECLARE()

Form.format.currentValue:="png"
Form.format.index:=0
Form.fidelity.currentValue:="strict"
Form.fidelity.index:=0
Form.vector.currentValue:="preserve"
Form.vector.index:=1
Form.printer.currentValue:="ignore"
Form.printer.index:=0
Form.width:=""
Form.height:=""
Form.dpi:=""
Form.maxPixels:=""
Form.background:=""
Form.highlight:=""
Form.fontMap:=False
Form.resourceId:=""
Form.dataFork:=False

Lab_Convert
Form.status:="Options reset to CLI defaults"
