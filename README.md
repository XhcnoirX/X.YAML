# YAML-to-JSON

This is a basic YAML-to-JSON converter written in [InterSystems ObjectScript](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=PAGE_OBJECTSCRIPT). This should run without issue on InterSystems IRIS, or InterSystems Caché 2016.1 and higher.

## Installation

To install, import X.YAML.xml in the namespace of your choice and compile it. Or create a new class called X.YAML, copy-paste the contents of X.YAML.cls into it, and compile it.

## Usage

To use:
```
// read in YAML file from disk, here my.yaml
set obj = ##class(X.YAML).ToJSON( "C:\Temp\my.yaml" )
// 'obj' now contains JSON representation of my.yaml
// display as string
write obj.%ToJSON()
// or use directly, for instance if the root object of my.yaml contains a 'foo' property with 'bar' as its string value
write obj.foo // displays: bar
```

## Limitations

There are a number of limitations:
- The YAML file needs to be indented correctly
- Array elements need to be at 1 indentation level deeper than the array itself
- Number parsing (floats, octals, ...) needs work
- ...

These limitations will be addressed in future versions.
