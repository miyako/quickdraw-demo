// Lab — thin, UI-agnostic wrapper around cs.QuickDraw.Converter.
// The form only owns presentation; every CLI call goes through this class.

property target : Text
property converter : Object
property samplesFolder : 4D.Folder
property outputFolder : 4D.Folder
property previewFolder : 4D.Folder

Class constructor

	This.target:="macOS-universal"
	If (Is Windows)
		This.target:="Windows-x64"
	End if
	This.converter:=cs.QuickDraw.Converter.new(This.target)
	var $resources : Text
	var $database : Text
	If (Is Windows)
		$resources:=Get 4D folder(Current resources folder)
		$database:=Get 4D folder(Database folder)
		This.samplesFolder:=Folder($resources+"Samples"; fk platform path)
		This.outputFolder:=Folder($database+"Output"; fk platform path)
	Else
		$resources:=Convert path system to POSIX(Get 4D folder(Current resources folder))
		$database:=Convert path system to POSIX(Get 4D folder(Database folder))
		This.samplesFolder:=Folder($resources+"Samples"; fk posix path)
		This.outputFolder:=Folder($database+"Output"; fk posix path)
	End if
	// Get 4D folder has no temporary-folder selector (the compiler rejects it);
	// use the Temporary folder command. It can be empty under tool4d --dataless,
	// so fall back to Output/preview.
	var $temporary : Text
	$temporary:=Temporary folder
	This.previewFolder:=Null
	If ($temporary#"")
		If (Is Windows)
			This.previewFolder:=Folder($temporary+"quickdraw-demo"; fk platform path)
		Else
			This.previewFolder:=Folder(Convert path system to POSIX($temporary)+"quickdraw-demo"; fk posix path)
		End if
	End if
	If (This.previewFolder=Null)
		This.previewFolder:=This.outputFolder.folder("preview")
	End if
	If (Not(This.outputFolder.exists))
		var $created : Boolean
		$created:=This.outputFolder.create()
	End if
	If (Not(This.previewFolder.exists))
		var $createdPreview : Boolean
		$createdPreview:=This.previewFolder.create()
	End if

// Names of sample files shipped in /RESOURCES/Samples, sorted.
Function samples() : Collection

	var $names : Collection
	$names:=New collection()
	var $file : 4D.File
	For each ($file; This.samplesFolder.files())
		var $extension : Text
		// File.extension keeps its dot (".pict") and File.name drops it.
		$extension:=Lowercase($file.extension)
		If (($extension=".pict") || ($extension=".rsrc"))
			$names.push($file.fullName)
		End if
	End for each
	$names.sort()
	return $names

Function sampleFile($name : Text) : 4D.File

	return This.samplesFolder.file($name)

Function version() : Object

	return This.converter.version()

Function capabilities() : Object

	return This.converter.capabilities()

Function inspect($input : 4D.File; $options : Object) : Object

	var $result : Object
	$result:=This.converter.inspect($input; $options)
	return $result

Function listPictures($input : 4D.File; $options : Object) : Object

	var $result : Object
	$result:=This.converter.listPictures($input; $options)
	return $result

Function listFonts($input : 4D.File; $options : Object) : Object

	var $result : Object
	$result:=This.converter.listFonts($input; $options)
	return $result

Function convert($input : 4D.File; $output : 4D.File; $options : Object) : Object

	var $result : Object
	$result:=This.converter.convert($input; $output; $options)
	return $result

// Object-based dropdown value, resilient to a missing currentValue.
Function choice($drop : Object) : Text

	var $value : Text
	$value:=""
	var $index : Integer
	$index:=-1
	If (Value type($drop.index)=Is real)
		$index:=$drop.index
	End if
	If ((Value type($drop.values)=Is collection) && ($index>=0) && ($index<$drop.values.length))
		$value:=String($drop.values[$index])
	End if
	If ($value="")
		If (Value type($drop.currentValue)=Is text)
			$value:=$drop.currentValue
		End if
	End if
	return $value

Function isInteger($text : Text) : Boolean

	return Match regex("^-?[0-9]+$"; Trim($text))

Function isPositiveInteger($text : Text) : Boolean

	return Match regex("^[0-9]+$"; Trim($text))

Function isDecimal($text : Text) : Boolean

	return Match regex("^[0-9]+([.][0-9]+)?$"; Trim($text))

Function isColor($text : Text) : Boolean

	return Match regex("^[0-9A-Fa-f]{6}$"; Trim($text))

// Sample-specific selection the CLI needs: drawing.rsrc holds two PICTs (pick one
// by exact ID) and text.pict needs the explicit NFNT font map.
Function sampleDefaults($name : Text) : Object

	var $defaults : Object
	$defaults:=New object("resourceId"; ""; "fontMap"; False)
	If ($name="drawing.rsrc")
		$defaults.resourceId:="128"
	End if
	If ($name="text.pict")
		$defaults.fontMap:=True
	End if
	return $defaults

// 4D's "&x" format already yields the 0x prefix ("0x0051").
Function opcodeHex($opcode : Real) : Text

	return String($opcode; "&x")

// Names of numeric/colour fields that hold text the option builders will drop,
// so the UI can say so instead of silently using the CLI default.
Function invalidFields($form : Object) : Collection

	var $invalid : Collection
	$invalid:=New collection()
	If ((String($form.width)#"") && Not(This.isPositiveInteger(String($form.width))))
		$invalid.push("width")
	End if
	If ((String($form.height)#"") && Not(This.isPositiveInteger(String($form.height))))
		$invalid.push("height")
	End if
	If ((String($form.dpi)#"") && Not(This.isDecimal(String($form.dpi))))
		$invalid.push("DPI")
	End if
	If ((String($form.maxPixels)#"") && Not(This.isPositiveInteger(String($form.maxPixels))))
		$invalid.push("max pixels")
	End if
	If ((String($form.resourceId)#"") && Not(This.isInteger(String($form.resourceId))))
		$invalid.push("resource ID")
	End if
	If ((String($form.background)#"") && Not(This.isColor(String($form.background))))
		$invalid.push("background")
	End if
	If ((String($form.highlight)#"") && Not(This.isColor(String($form.highlight))))
		$invalid.push("highlight")
	End if
	return $invalid

// Input-scope options only: valid for inspect, list-pictures and list-fonts.
Function inputOptions($form : Object; $withSelection : Boolean) : Object

	var $options : Object
	$options:=New object()
	$options["container"]:=This.choice($form.container)
	If (This.isPositiveInteger(String($form.maxPixels)))
		$options["max-pixels"]:=Trim(String($form.maxPixels))
	End if
	If ($withSelection)
		If (Bool($form.dataFork))
			$options["data-fork"]:=True
		Else
			If (This.isInteger(String($form.resourceId)))
				$options["resource-id"]:=Trim(String($form.resourceId))
			End if
		End if
	End if
	return $options

// Full convert options, plus selection and explicit font map.
Function convertOptions($form : Object) : Object

	var $options : Object
	$options:=This.inputOptions($form; True)
	$options["format"]:=This.choice($form.format)
	$options["fidelity"]:=This.choice($form.fidelity)
	$options["printer-comments"]:=This.choice($form.printer)
	If ($options.format#"png")
		$options["vector-policy"]:=This.choice($form.vector)
	End if
	If (This.isPositiveInteger(String($form.width)))
		$options["width"]:=Trim(String($form.width))
	End if
	If (This.isPositiveInteger(String($form.height)))
		$options["height"]:=Trim(String($form.height))
	End if
	If (This.isDecimal(String($form.dpi)))
		$options["dpi"]:=Trim(String($form.dpi))
	End if
	If (This.isColor(String($form.background)))
		$options["background"]:=Trim(String($form.background))
	End if
	If (This.isColor(String($form.highlight)))
		$options["highlight"]:=Trim(String($form.highlight))
	End if
	If (Bool($form.fontMap))
		$options["font-map"]:=This.samplesFolder.file("fonts.json")
	End if
	return $options

// Always rasterise a PNG preview, even when the chosen output is SVG/PDF or
// when strict mode rejects the picture. Approximation is explicit and scoped
// to the preview path only.
Function preview($input : 4D.File; $options : Object) : Object

	var $pngOptions : Object
	$pngOptions:=OB Copy($options; True)
	$pngOptions["format"]:="png"
	$pngOptions["fidelity"]:="approximate"
	$pngOptions["overwrite"]:=True
	If ($pngOptions["vector-policy"] #Null)
		OB REMOVE($pngOptions; "vector-policy")
	End if
	var $file : 4D.File
	$file:=This.previewFolder.file("preview.png")
	If ($file.exists)
		var $deleted : Boolean
		$deleted:=$file.delete()
	End if
	var $result : Object
	$result:=This.converter.convert($input; $file; $pngOptions)
	var $picture : Picture
	If (Bool($result.ok))
		READ PICTURE FILE($file.platformPath; $picture)
	End if
	return New object("result"; $result; "picture"; $picture; "file"; $file)

Function digest($file : 4D.File) : Text

	If ($file.exists)
		var $blob : Blob
		$blob:=$file.getContent()
		var $digest : Text
		$digest:=Generate digest($blob; SHA256 digest)
		return Lowercase($digest)
	End if
	return ""

// Human-readable error line, including the CLI's offset/opcode evidence.
Function failureText($result : Object) : Text

	If (Bool($result.ok))
		return "ok"
	End if
	var $text : Text
	$text:=String($result.failureKind)
	If (Value type($result.error)=Is object)
		$text:=$text+": "+String($result.error.code)
		If (String($result.error.message)#"")
			$text:=$text+" — "+String($result.error.message)
		End if
		If (Value type($result.error.offset)=Is real)
			$text:=$text+" (offset "+String($result.error.offset)
			If (Value type($result.error.opcode)=Is real)
				$text:=$text+", opcode "+String($result.error.opcode)
			End if
			$text:=$text+")"
		End if
	End if
	return $text
