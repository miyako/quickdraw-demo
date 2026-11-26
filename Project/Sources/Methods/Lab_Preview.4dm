//%attributes = {"invisible":true}
// Rasterise a preview independently of the requested output format.
#DECLARE($input : 4D.File; $options : Object; $convertResult : Object)

var $preview : Object
$preview:=Form.lab.preview($input; $options)
Form.preview:=$preview.picture

var $info : Text
If (Bool($preview.result.ok))
	var $value : Object
	$value:=$preview.result.value
	$info:="Approximate PNG preview · "+String($value.width)+"×"+String($value.height)+" · "+String($value.bytes)+" B"
	If (Value type($convertResult)=Is object)
		If (Bool($convertResult.ok))
			$info:=$info+" · requested output verified"
		Else
			$info:=$info+" · the strict conversion above was rejected"
		End if
	End if
Else
	$info:="No preview available — "+Form.lab.failureText($preview.result)
End if
Form.previewInfo:=$info
