<?xml version="1.0" encoding="utf-8"?>
<!-- -*- mode: xsl; coding: utf8; -*- -->
<!-- Author: pajas@ufal.ms.mff.cuni.cz -->

<xsl:stylesheet
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform' 
  xmlns:p="http://ufal.mff.cuni.cz/pdt/pml/"
  version='1.0'>
<xsl:output method="html" encoding="utf-8"/>

<xsl:template match="/">
  <html>
    <head>
      <style>
/* <xsl:comment> */
.package {
   background-color: #ffffff;
   border: solid 1px #aaf;
 /*   padding: 0 12pt 6pt 12pt; */
   margin: 10pt 10pt 10pt 10pt;
}

.pkghead {
    background-color: #eeeeff;
    padding: 3pt 3pt 3pt 3pt;
}

.pkgtitle {
    font-weight: bold;
    padding: 3pt 3pt 3pt 3pt;
}

.desc {
    padding: 3pt 3pt 3pt 3pt;
}

.copyright {
    font-size: 7pt;
    font-style: italic;
    text-align: right;
    color: #666;
    padding: 3pt 3pt 3pt 3pt;
}
/* </xsl:comment> */
</style>
      <link href="style.css" rel="stylesheet"/>
    </head>
    <body>
      <xsl:apply-templates/>
    </body>
  </html>
</xsl:template>

<xsl:template match="p:tred_extension">
  <div class="package">
    <div class="pkghead">
      <span class="pkgtitle">
	<xsl:apply-templates select="p:title"/>
      </span>
      <span class="version">
	(<xsl:apply-templates select="p:pkgname"/> 
	<xsl:text>&#x20;</xsl:text>
	<xsl:apply-templates select="p:version"/>)
      </span>
    </div>
    <div class="desc">
      <xsl:apply-templates select="p:description"/>
   </div>
   <div class="copyright">
     <xsl:apply-templates select="p:copyright"/>
   </div>    
  </div>
</xsl:template>

<xsl:template match="p:copyright">
  <xsl:text>Copyright (c) </xsl:text>
  <xsl:apply-templates select="@year"/>
  <xsl:text> by </xsl:text>
  <xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>