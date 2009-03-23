<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform' 
  xmlns="http://ufal.mff.cuni.cz/pdt/pml/"
  version='1.0'>
  
<xsl:output method="xml" encoding="utf-8"/>
<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="example problem"/>

<xsl:template match="/">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="valency_lexicon">
  <xsl:element name="{local-name()}" namespace="http://ufal.mff.cuni.cz/pdt/pml/">
    <xsl:apply-templates select="@*"/>
    <head>
      <schema href="vallex_schema.xml"/>
    </head>
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

<!-- cleanup unused stuff -->
<xsl:template match="head|tail|local_history"/>
<xsl:template match="@hereditary_used"/>
<xsl:template match="@orig_type"/>

<xsl:template match="*">
  <xsl:element name="{local-name()}" namespace="http://ufal.mff.cuni.cz/pdt/pml/">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="@*">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>
