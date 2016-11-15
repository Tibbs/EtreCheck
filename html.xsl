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
  
    <dl class="problem">
      <dt>Problem:</dt>
      <dd><xsl:value-of select="problem/type"/></dd>
      
      <xsl:if test="problem/description">
        <dt>Description:</dt>
        <dd><xsl:value-of select="problem/description"/></dd>
      </xsl:if>
    </dl>
      
  </xsl:template>

  <xsl:template match="hardware">
  
    <h1>Hardware Information: ⓘ</h1>
    <p><xsl:value-of select="marketingname"/></p>
    <dl>
      <dt>Class - model:</dt>
      <dd><xsl:value-of select="model"/></dd>
    </dl>
    <p><xsl:value-of select="cpucount"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="cpuspeed"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="cputype"/>
      <xsl:text> </xsl:text>(part #) CPU:<xsl:text> </xsl:text>
      <xsl:value-of select="corecount"/>-core</p>
    <p><xsl:value-of select="total"/> RAM</p>
    <ul>
    <xsl:for-each select="memorybanks/memorybank">
      <li>
        <dl>
          <dt><xsl:value-of select="name"/></dt>
          <dd>
            <xsl:value-of select="size"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="type"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="speed"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="status"/>
          </dd>
        </dl>
      </li>
    </xsl:for-each>
    </ul>
    <dl class="hardware">
      <dt>Handoff:</dt>
      <dd><xsl:value-of select="supportshandoff"/></dd>
      <dt>Instant Hotspot:</dt>
      <dd><xsl:value-of select="supportsinstanthotspot"/></dd>
      <dt>Low energy:</dt>
      <dd><xsl:value-of select="supportslowenergy"/></dd>
      <dt>Wireless:</dt>
      <dd><xsl:value-of select="wirelessinterfaces/wirelessinterface/name"/></dd>
      <dd><xsl:value-of select="wirelessinterfaces/wirelessinterface/modes"/></dd>
      <dt>Battery:</dt>
      <dd>Health = <xsl:value-of select="batteryinformation/battery/health"/> - Cycle count = <xsl:value-of select="batteryinformation/battery/cyclecount"/></dd>
    </dl>
  </xsl:template>
 
  <xsl:template match="*">
  
    <div class="section">
      <h1><xsl:value-of select="name(.)"/></h1>
    </div>
    
  </xsl:template>

</xsl:stylesheet>
