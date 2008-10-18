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
* {
  font-family: sans;
}
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
.size {
  text-align: right;
  font-size: 7pt;
  padding: 3pt 3pt 0pt 3pt;
}
.copyright {
    font-size: 7pt;
    font-style: italic;
    text-align: right;
    color: #666;
    padding: 3pt 3pt 3pt 3pt;
}
.version {
    text-align: right;
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
      <xsl:call-template name="icon"/>
        <xsl:apply-templates select="p:description"/>
   </div>
   <xsl:if test="@package_size|@install_size">
     <div class="size">
       <xsl:text>Size: </xsl:text>
       <xsl:if test="@package_size">
	 <xsl:call-template name="format_size">
	   <xsl:with-param name="size" select="@package_size"/>
	 </xsl:call-template>
	 <xsl:text> package </xsl:text>
	 <xsl:if test="@install_size">
	   <xsl:text>/ </xsl:text>
	 </xsl:if>
       </xsl:if>
       <xsl:if test="@install_size">
	 <xsl:call-template name="format_size">
	   <xsl:with-param name="size" select="@install_size"/>
	 </xsl:call-template>
	 <xsl:text> installed</xsl:text>
       </xsl:if>
     </div>
   </xsl:if>
   <div class="copyright" style="clear:both">
     <xsl:apply-templates select="p:copyright"/>
   </div>    
  </div>
</xsl:template>

<xsl:template name="format_size">
  <xsl:param name="size"/>
  <xsl:choose>
    <xsl:when test="1024 > $size">
      <xsl:value-of select="$size"/>
      <xsl:text> B</xsl:text>
    </xsl:when>
    <xsl:when test="1024*1024 > $size">
      <xsl:value-of select="round($size div 1024)"/>
      <xsl:text> KiB</xsl:text>
    </xsl:when>
    <xsl:when test="1024*1024*1024 > $size">
      <xsl:value-of select="round($size div (1024*1024))"/>
      <xsl:text> MiB</xsl:text>
    </xsl:when>
    <xsl:when test="1024*1024*1024*1024 > $size">
      <xsl:value-of select="round($size div (1024*1024*1024))"/>
      <xsl:text> GiB</xsl:text>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template match="p:copyright">
  <xsl:text>Copyright (c) </xsl:text>
  <xsl:apply-templates select="@year"/>
  <xsl:text> by </xsl:text>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template name="icon">
<!--  <span class="icon"> -->
    <xsl:choose>
      <xsl:when test="p:icon">
      <img src="{concat(string(p:pkgname),'/',string(p:icon))}" style="float: left; padding: 6pt 6pt 0pt 6pt"/>
      </xsl:when>
      <xsl:otherwise>
	<img src="extension.png" style="float: left; padding: 6pt 6pt 0pt 6pt" />
    </xsl:otherwise>
    </xsl:choose>
<!--  </span> -->
</xsl:template>

</xsl:stylesheet>
