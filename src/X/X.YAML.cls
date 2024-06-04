/// A YAML-to-JSON converter written in InterSystems ObjectScript
Class X.YAML Extends %RegisteredObject
{

ClassMethod ToJSON(file As %String = "") As %DynamicAbstractObject
{
	set lines = []
	if $zconvert($e(file,1,4),"l")="http" {
		// load from URL
		// ...
	} else {
		// load from file
		if '##class(%File).Exists(file) {
			set $zerror = "File not found!"
			throw
		}
		set stream = ##class(%Stream.FileCharacter).%New()
		set status = stream.LinkToFile(file)
		While 'stream.AtEnd {
			do lines.%Push(stream.ReadLine())
		}
	}
	if +lines.%Size()=0 {
		set $zerror = "File empty!"
		throw
	}
	// first line needs to be '---'
	if ..StripComment(lines.%Remove(0))'="---" {
		set $zerror = "File does not start with ---!"
		throw
	}
	set json = {} // assume object for now
	do ..GetNextGroup(.json, .lines)
	quit json
}

/// Separated method in case of specific usecases
ClassMethod StripComment(line As %String = "") As %String
{
	// strip unless # is inside " ... " text
	quit $p(line,"#")
}

/// Assume indentation is uniform across the document!
ClassMethod GetIndentLevel(line As %String = "") As %Integer
{
	set lvl = 0
	while ($e(line,1,^||IndentCharacterLength)=^||IndentCharacter) {
		set lvl = lvl+1
		set line = $e(line,^||IndentCharacterLength+1,*)
	}
	quit lvl
}

ClassMethod TrimLeft(line As %String = "") As %String
{
	set c = $ascii($e(line,1))
	while ((c=9) || (c=10) || (c=32)) {
		set line = $e(line,2,*)
		set c = $ascii($e(line,1))
	}
	quit line
}

ClassMethod ParseLine(line As %String, ByRef type As %String, ByRef key As %String, ByRef valueToStore As %RegisteredObject)
{
	set key = $p(line,":")
	set originalValue = ..TrimLeft($P(line,":",2,999))
	set c = $e(originalValue,1)
	set a = $ascii(c)
	set origValLC = $zconvert(originalValue, "l")
	if a=34 {
		set type = "string"
		set valueToStore = $e(originalValue,2,*-1)
	}
	elseif (origValLC="true") || (origValLC="on") || (origValLC="yes") {
		set type = "boolean"
		set valueToStore = 1
	}
	elseif (origValLC="false") || (origValLC="off") || (origValLC="no") {
		set type = "boolean"
		set valueToStore = 0
	}
	elseif (a>=48) && (a<=57) {
		set type = "number"
		set valueToStore = +originalValue
	}
	elseif (c="~") || (c="null") {
		set type = "null"
		set valueToStore = ""
	}
	elseif originalValue="" {
		// can be array or object
		set type = "arrobj"
	}
	elseif c=">" {
		set type = "block"
	}
	elseif c="|" {
		set type = "multiline"
	}
	elseif c="&" {
		set type = "setreference"
		set valueToStore = $e(originalValue,2,*)
	}
	elseif c="*" {
		set type = "getreference"
		set valueToStore = $e(originalValue,2,*)
	}
	else {
		set type = "string"
		set valueToStore = originalValue
	}
}

ClassMethod GetTab(line As %String = "") As %String
{
	// tabs or spaces
	set c = $e(line,1)
	set a = $ascii(c)
	if (a'=32) && (a'=9) {
		quit ""
		set $zerror = "Indentation issue!"
		throw
	}
	set p = 2
	set tab = c
	while ($e(line,p)=c) {
		set tab = tab _ c
		set p = p + 1
	}
	quit tab
}

/// Parse the current object and return it
ClassMethod ParseObject(lines As %DynamicArray) As %DynamicObject
{
	set obj = {}
	
	quit obj
}

/// Parse the current array and return it
ClassMethod ParseArray() As %DynamicArray
{
	set arr = []
	quit arr
}

ClassMethod GetNextGroup(ByRef json As %DynamicAbstractObject, ByRef lines As %DynamicArray)
{
	if 'lines.%Size() quit ""
	set group = {}
	set line = lines.%Remove(0)
	// determine type of this line
	do ..ParseLine(line, .type, .key, .value)
	set group.key = key
	if (type="arrobj") || (type="block") || (type="multiline") {
		set offset1 = $l(..GetTab(line)) // not foolproof
		set offset2 = 0
		set group.lines = []
		set line = lines.%Get(0)
		while $l(..GetTab(line))>offset1 {
			if 'offset2 set offset2 = $l(..GetTab(line))
			set line = $e(line,offset2+1,*)
			if type="arrobj" {
				if $e(line,1)="-" {
					set type = "arr"
				} else {
					set type = "obj"
				}
			}
			do group.lines.%Push(line)
			do lines.%Remove(0)
			set line = lines.%Get(0)
		}
	} else {
		set group.value = value
	}
	set group.type = type
	//w !,"Group "_group.%ToJSON()
	do ..AddGroupToJSON(.json, .group)
	//
	quit ..GetNextGroup(.json, .lines)
}

ClassMethod AddGroupToJSON(ByRef json As %DynamicAbstractObject, ByRef group As %DynamicObject)
{
	set type = group.type
	if (type="string") || (type="number") || (type="boolean") || (type="null") {
		if group.key="" {
			do json.%Push(group.value, type)
		}
		else {
			do json.%Set(group.key, group.value, type)
		}
	}
	elseif (type="arr") || (type="obj") {
		set store = {}
		if type="arr" set store = []
		set iter = group.lines.%GetIterator()
		while iter.%GetNext(.key, .value) {
			w !,key_": "_value
			if type="arr" set value = ..TrimLeft($e(value,2,*))
			// TODO: item is complex object/array/...
			if value[":" {
				do ..ParseLine(value, .itemType, .itemKey, .itemValue)
				w !,itemType_" "_itemKey
				set temp = {}
				set temp.type = itemType
				set temp.key = ""
				set temp.value = itemValue
				do store.%Set(itemKey, itemValue, itemType)
			} else {
				if type="arr" do store.%Push(value)
				// obj??
			}
		}
		do json.%Set(group.key, .store)
	}
	else {
		w !,group.%ToJSON()
	}
	quit
}

}
