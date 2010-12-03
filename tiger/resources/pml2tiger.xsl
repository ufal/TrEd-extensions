<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
<!-- -*- mode: xsl; coding: ISO-8859-1; -*- -->
<!-- Authors: Maud Medves with the help of Laurent Romary -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:pml="http://ufal.mff.cuni.cz/pdt/pml/" xmlns:s="http://ufal.mff.cuni.cz/pdt/pml/schema/"
  xmlns:t="http://www.tiger.edu" version="1.0">
  <xsl:output method="xml" encoding="utf-8" indent="yes"/>
  <xsl:strip-space elements="*"/>


  <!-- General structure, creation of main components: head and body -->

  <xsl:template match="/">
    <corpus>
      <xsl:attribute name="id">
        <xsl:value-of select="pml:corpus/pml:meta/pml:name"/>
      </xsl:attribute>
      <head>
        <xsl:apply-templates select="pml:corpus/pml:meta"/>
        <xsl:apply-templates select="pml:corpus/pml:head/pml:schema"/>
      </head>
      <body>
        <xsl:apply-templates select="pml:corpus/pml:body/pml:s"/>
      </body>
    </corpus>
  </xsl:template>


  <!-- Metadata info here -->

  <xsl:template match="pml:corpus/pml:meta">
    <meta>
      <name>
        <xsl:value-of select="pml:name"/>
      </name>
      <author>
        <xsl:value-of select="pml:author"/>
      </author>
      <date>
        <xsl:value-of select="pml:date"/>
      </date>
      <description>
        <xsl:value-of select="pml:description"/>
      </description>
      <format>
        <xsl:value-of select="pml:format"/>
      </format>
    </meta>
  </xsl:template>

  <!-- Annotation info here -->

  <xsl:template match="pml:corpus/pml:head/pml:schema">
    <annotation>
      <xsl:apply-templates select="s:pml_schema/s:type[@name='terminal.type']"/>
      <xsl:apply-templates select="s:pml_schema/s:type[@name='nonterminal.type']"/>
      <xsl:apply-templates select="s:pml_schema/s:type[@name='edgelabel.type']"/>
      <xsl:apply-templates select="s:pml_schema/s:type[@name='secedge.type']"/>
    </annotation>
  </xsl:template>

  <!-- Directly here for features belonging to T or NT domains -->

  <xsl:template match="s:type[@name='nonterminal.type' or @name='terminal.type']">
    <xsl:apply-templates select="s:structure/s:member"/>
  </xsl:template>

  <xsl:template
    match="s:member[@name='word' or @name='lemma' or @name='pos' or @name='morph' or @name='case' or @name='number' or @name='gender' or @name='person' or @name='degree' or @name='tense' or @name='mood' or @name='cat']">
    <feature>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="domain">
        <xsl:choose>
          <xsl:when test="ancestor::s:type[1]/@name='nonterminal.type'">
            <xsl:text>NT</xsl:text>
          </xsl:when>
          <xsl:when test="ancestor::s:type[1]/@name='terminal.type'">
            <xsl:text>T</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="s:choice/s:value"/>
    </feature>
  </xsl:template>

  <xsl:template match="s:member"/>

  <!-- Edelabel here -->
  <xsl:template match="s:type[@name='edgelabel.type']">
    <edgelabel>
      <xsl:apply-templates select="s:choice/s:value"/>
    </edgelabel>
  </xsl:template>

  <!-- Secedgelabel here -->
  <xsl:template match="s:type[@name='secedge.type']">
    <secedgelabel>
      <xsl:apply-templates select="s:structure/s:member/s:choice/s:value"/>
    </secedgelabel>
  </xsl:template>

  <!-- Value of annotations here (embedded in features, edgelabels or secedgelabels) -->

  <xsl:template match="s:value">
    <value>
      <xsl:attribute name="name">
        <xsl:value-of select="."/>
      </xsl:attribute>
    </value>
  </xsl:template>

  <!-- s info here (belongs to the body element)  -->

  <xsl:template match="pml:corpus/pml:body/pml:s">
    <s>
      <xsl:attribute name="id">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:apply-templates select="pml:root"/>
    </s>
  </xsl:template>

  <!-- Structure of the graph element: (ordered) terminals and nonterminals -->

  <xsl:template match="pml:corpus/pml:body/pml:s/pml:root">
    <graph>
      <xsl:attribute name="root">
        <xsl:value-of select="pml:nonterminal/@id"/>
      </xsl:attribute>
      <terminals>
        <xsl:apply-templates select="descendant::pml:terminal">
          <xsl:sort select="pml:order" data-type="number" order="ascending"/>
        </xsl:apply-templates>
      </terminals>
      <nonterminals>
        <xsl:apply-templates select="descendant::pml:nonterminal"/>
      </nonterminals>
    </graph>
  </xsl:template>

  <!-- Building the terminals representation: id, word, lemma, pos, morph
case, number, gender, person, degree, tense, mood, secedge  -->

  <xsl:template match="pml:terminal">
    <t>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="pml:word"/>
      <xsl:apply-templates select="pml:lemma"/>
      <xsl:apply-templates select="pml:pos"/>
      <xsl:apply-templates select="pml:morph"/>
      <xsl:apply-templates select="pml:case"/>
      <xsl:apply-templates select="pml:number"/>
      <xsl:apply-templates select="pml:gender"/>
      <xsl:apply-templates select="pml:person"/>
      <xsl:apply-templates select="pml:degree"/>
      <xsl:apply-templates select="pml:tense"/>
      <xsl:apply-templates select="pml:mood"/>
      <xsl:apply-templates select="descendant::pml:secedge"/>
    </t>
  </xsl:template>

  <xsl:template match="pml:word">
    <xsl:attribute name="word">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:lemma">
    <xsl:attribute name="lemma">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:pos">
    <xsl:attribute name="pos">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:morph">
    <xsl:attribute name="morph">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:case">
    <xsl:attribute name="case">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:number">
    <xsl:attribute name="number">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:gender">
    <xsl:attribute name="gender">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:person">
    <xsl:attribute name="person">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:degree">
    <xsl:attribute name="degree">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:tense">
    <xsl:attribute name="tense">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="pml:mood">
    <xsl:attribute name="mood">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- Building the nonterminals representation: id, cat, edge and secedge -->

  <xsl:template match="pml:nonterminal">
    <nt>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="pml:cat"/>
      <xsl:apply-templates select="pml:children/pml:terminal/pml:label"/>
      <xsl:apply-templates select="pml:children/pml:nonterminal/pml:label"/>
      <xsl:apply-templates select="pml:secedges/pml:secedge"/>
    </nt>
  </xsl:template>

  <xsl:template match="pml:cat">
    <xsl:attribute name="cat">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>


  <!-- Edges representation: id and label -->

  <xsl:template match="pml:terminal/pml:label | pml:nonterminal/pml:label">
    <edge>
      <xsl:attribute name="idref">
        <xsl:value-of select="parent::*/@id"/>
      </xsl:attribute>
      <xsl:attribute name="label">
        <xsl:value-of select="."/>
      </xsl:attribute>
    </edge>
  </xsl:template>


  <!-- Secedges representation: idref and label -->

  <xsl:template match="pml:secedge">
    <secedge>
      <xsl:if test="pml:label">
        <xsl:attribute name="label">
          <xsl:value-of select="pml:label"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="pml:idref">
        <xsl:attribute name="idref">
          <xsl:value-of select="pml:idref"/>
        </xsl:attribute>
      </xsl:if>
    </secedge>
  </xsl:template>


  <!-- General rule for identifying unknown elements ! -->

  <xsl:template match="*">
    <xsl:message terminate="no">Unknown element: <xsl:value-of select="name(.)"/> - <xsl:for-each
        select="attribute::*">
        <xsl:value-of select="name(.)"/>="<xsl:value-of select="."/>" </xsl:for-each>
    </xsl:message>
    <xsl:if test=".!=''">
      <xsl:element name="{name(.)}">
        <xsl:apply-templates/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>