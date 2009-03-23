<?xml version="1.0" encoding="utf-8"?>
<pmlbackend
  xmlns="http://ufal.mff.cuni.cz/pdt/pml/"
  xmlns:xi="http://www.w3.org/2001/XInclude">
  <head>
    <schema href="pmlbackend_conf_schema.xml"/>
  </head>
  <transform_map>
    <transform id="pml_vallex" test="valency_lexicon">
      <in type="xslt" href="vallex2pml.xsl"/>
    </transform>
  </transform_map>
</pmlbackend>
