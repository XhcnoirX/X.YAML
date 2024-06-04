# YAML-to-JSON

This is a basic YAML-to-JSON converter written in [InterSystems ObjectScript](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=PAGE_OBJECTSCRIPT). This should run without issue on any InterSystems Caché or InterSystems IRIS system.

## Installation

To install, import X.YAML.xml in the namespace of your choice and compile it. Or create a new class called X.YAML, copy-paste the contents of X.YAML.cls into it, and compile it.

## Usage

To use, ...

## Limitations

There are a number of limitations:
- The YAML file needs to be indented correctly
- Array elements need to be at 1 indentation level deeper than the array itself
- No support yet for inline objects or arrays
- ...

These limitations will be addressed in future versions.
