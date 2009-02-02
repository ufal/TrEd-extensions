#! /bin/bash

## Removes arg[0-9] attributes from pml schemata. Called by
## conll2009-to-pml.sh.
## Author: Jan Stepanek

xsh=xsh

for file ; do
    "$xsh" <<-XSH
	open '$file' ;
	rm /s:pml_schema/s:type[@name="node.type"]/s:structure[@role="#NODE"]/s:member[starts-with(@name,'apred_')] ;
	save ;
	XSH
done