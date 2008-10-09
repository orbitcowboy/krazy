<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY nbsp "&#160;">]>
<xsl:stylesheet version="2.0"
  xmlns:ebn="http://www.englishbreakfastnetwork.org/krazy"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml">
  
  <xsl:import href="functions.xsl" />
  <xsl:import href="globalvars.xsl" />
  
  <xsl:output doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
              doctype-system="DTD/xhtml1-transitional.dtd"
              encoding="UTF-8" 
              indent="yes"
              method="xhtml" 
              omit-xml-declaration="yes"
              version="1.0" />
  
  <xsl:template name="check">
    <xsl:param name="fileType" as="xsd:string" />
    
    <xsl:variable name="issueCount" as="xsd:integer" select="ebn:issueCount($fileType, @desc)" />
    
    <li>
      <span class="toolmsg">
        <xsl:choose>
          <xsl:when test="$issueCount > 0">
            <xsl:value-of select="@desc" /><b>OOPS! 
            <xsl:value-of select="$issueCount"/>
            issues found!</b>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@desc" /><b>okay!</b>
          </xsl:otherwise>
        </xsl:choose>
      </span>
      <ol>
      </ol>
      <xsl:if test="$issueCount > 0" >
        <p class="explanation"><xsl:value-of select="explanation" /></p>
      </xsl:if>
    </li>
  </xsl:template>
  
  <xsl:template name="file-type" >
    <xsl:variable name="fileType" select="@value" />
    <li>
      <b><u>For File Type <xsl:value-of select="$fileType" /></u></b>
      <ol>
        <xsl:for-each select="check">
          <xsl:call-template name="check">
            <xsl:with-param name="fileType" select="$fileType" />
          </xsl:call-template>
        </xsl:for-each>
      </ol>
    </li>
  </xsl:template>
  
  <xsl:template match="file-types" mode="krazy2ebn" >
    <xsl:for-each select="file-type">
      <xsl:call-template name="file-type"/>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="global" mode="krazy2ebn" >
    <h1>krazy2 Analysis</h1>
    <p>Checkers Run = <xsl:value-of select="ebn:checkerCount('all')" /><br />
    Files Processed = <xsl:value-of select="ebn:processedFilesCount()" /><br />
    Total Issues = <xsl:value-of select="ebn:issueCount('all','all')" /> 
    ...as of <xsl:value-of select="ebn:dateOfRun()" /></p>
  </xsl:template>
  
  <xsl:template match="/krazy" mode="krazy2ebn">
    <html xml:lang="en" lang="en">
      <head>
        <title>krazy2 Analysis</title>
        <link rel="stylesheet" type="text/css" title="Normal" 
          href="http://www.englishbreakfastnetwork.org/style.css" />
      </head>
      <body>
        <div id="title">
          <div class="logo">&nbsp;</div>
          <div class="header">
            <h1><a href="/">English Breakfast Network</a></h1>
            <p><a href="/">Almost, but not quite, entirely unlike tea.</a></p>
          </div>
        </div>
        <div id="content">
          <div class="inside">
            <p style="font-size: x-small;font-style: sans-serif;">
              <a href="/index.php">Home</a>&nbsp;&gt;&nbsp;
              <a href="/krazy2/index.php">Krazy Code Checker</a>&nbsp;&gt;&nbsp;
              <a href="/krazy2/index.php?component=KDE">KDE</a>&nbsp;&gt;&nbsp;
            </p>
            <xsl:apply-templates select="global" mode="krazy2ebn" />
            <ul>
              <xsl:apply-templates select="file-types" mode="krazy2ebn" />
            </ul>
          </div>
        </div>
      </body>
     </html>
  </xsl:template>
  
</xsl:stylesheet>

<!-- kate:space-indent on; -->