<?xml version="1.0"?>
<xsl:stylesheet 
  version = '1.0' 
  xmlns="http://www.w3.org/1999/xhtml" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/> 
 
  <xsl:template match='/etrecheck'>
  
    <html>
    
      <head>
        <title>EtreCheck Report</title>
      </head>

      <body>
      
        <xsl:apply-templates select="stats"/>
        <xsl:apply-templates select="problem"/>
        <xsl:apply-templates select="hardware"/>
        <xsl:apply-templates select="video"/>
        <xsl:apply-templates select="systemsoftware"/>
        <xsl:apply-templates select="disk"/>
        <xsl:apply-templates select="usb"/>
        <xsl:apply-templates select="firewire"/>
        <xsl:apply-templates select="thunderbolt"/>
        <xsl:apply-templates select="configurationfiles"/>
        <xsl:apply-templates select="gatekeeper"/>
        <xsl:apply-templates select="adware"/>
        <xsl:apply-templates select="unknownfiles"/>
        <xsl:apply-templates select="kernelextensions"/>
        <xsl:apply-templates select="startupitems"/>
        <xsl:apply-templates select="systemlaunchagents"/>
        <xsl:apply-templates select="systemlaunchdaemons"/>
        <xsl:apply-templates select="launchagents"/>
        <xsl:apply-templates select="launchdaemons"/>
        <xsl:apply-templates select="userlaunchagents"/>
        <xsl:apply-templates select="loginitems"/>
        <xsl:apply-templates select="internetplugins"/>
        <xsl:apply-templates select="userinternetplugins"/>
        <xsl:apply-templates select="safariextensions"/>
        <xsl:apply-templates select="audioplugins"/>
        <xsl:apply-templates select="useraudioplugins"/>
        <xsl:apply-templates select="itunesplugins"/>
        <xsl:apply-templates select="useritunesplugins"/>
        <xsl:apply-templates select="preferencepanes"/>
        <xsl:apply-templates select="fonts"/>
        <xsl:apply-templates select="timemachine"/>
        <xsl:apply-templates select="cpu"/>
        <xsl:apply-templates select="memory"/>
        <xsl:apply-templates select="vm"/>
        <xsl:apply-templates select="diagnostics"/>
        <xsl:apply-templates select="etrecheckdeletedfiles"/>
            
      </body>

    </html>

  </xsl:template>

  <xsl:template match="stats">
  
    <div class="header">
      <p>EtreCheck version: <xsl:value-of select="/etrecheck/@version"/> (<xsl:value-of select="/etrecheck/@build"/>)</p>
      <p>Report generated <xsl:value-of select="date"/></p>
      <p>Download EtreCheck from https://etrecheck.com</p>
      <p>Runtime <xsl:value-of select="runtime"/></p>
      <p>Performance: <xsl:value-of select="performance"/></p>
    </div>
    
    <div class="instructions">
      <p>Click the [Support] links for help with non-Apple products.</p>
      <p>Click the [Details] links for more information about that line.</p>
    </div>

  </xsl:template>

  <xsl:template match="problem">
  
    <div class="problem">
      <p>Problem: <xsl:value-of select="problem/type"/></p>
      <p><xsl:value-of select="problem/description"/></p>
    </div>
      
  </xsl:template>

  <xsl:template match="*">
  
    <div class="section">
      <h1><xsl:value-of select="name(.)"/></h1>
    </div>
    
  </xsl:template>

</xsl:stylesheet>
