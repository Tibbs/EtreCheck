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
  
    <h1>Hardware Information:</h1>
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
 
  <xsl:template match="video">
  
    <h1>Video Information:</h1>
    <ul>
      <xsl:for-each select="videocard">
        <p><xsl:value-of select="name"/></p>
        <xsl:if test="count(display) &gt; 0">
          <li>
            <ul>
              <xsl:for-each select="display">
                <li>
                  <xsl:value-of select="name"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="resolution"/>
                </li>
              </xsl:for-each>
            </ul>
          </li>
        </xsl:if>
      </xsl:for-each>
    </ul>   
  </xsl:template>

  <xsl:template match="systemsoftware">
  
    <h1>System Software:</h1>
    <p>
      <xsl:value-of select="version"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="concat('(', build,')')"/>
      <xsl:text> - Time since boot: </xsl:text>
      <xsl:value-of select="humanuptime"/>
    </p>

  </xsl:template>

  <xsl:template match="disk">
  
    <h1>Disk Information:</h1>
    <ul>
      <xsl:for-each select="controller">
        <xsl:for-each select="disk">
          <p>
            <xsl:value-of select="name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="device"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="concat('(', size, ')')"/>
            <xsl:value-of select="concat('(', type, ' - TRIM: ', TRIM,')')"/>
            <xsl:if test="SMART != 'Verified'">
              <xsl:value-of select="concat('S.M.A.R.T. Status: ', SMART)"/>
            </xsl:if>
          </p>
          <xsl:if test="count(volumes/volume) &gt; 0">
            <li>
              <ul>
                <xsl:for-each select="volumes/volume">
                  <li>
                    <xsl:value-of select="name"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="concat('(', device, ')')"/>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                      <xsl:when test="mount_point">
                        <xsl:value-of select="mount_point"/>
                      </xsl:when>
                      <xsl:default>
                        <xsl:text> &lt;not mounted&gt; </xsl:text>
                      </xsl:default>
                    </xsl:choose>
                    <xsl:text> </xsl:text>
                    <xsl:if test="type">
                      <xsl:value-of select="concat('[', type, ']')"/>
                    </xsl:if>
                    <xsl:text>: </xsl:text>
                    <xsl:value-of select="size"/>
                    <xsl:if test="free_space">
                      <xsl:value-of select="concat(' (', free_space, ' free)')"/>
                    </xsl:if>
                    <xsl:if test="@encrypted = 'yes'">
                      <br/>
                      <xsl:text>Encrypted </xsl:text>
                      <xsl:value-of select="@encryption_type"/>
                      <xsl:choose>
                        <xsl:when test="@encryption_locked = 'no'">
                          <xsl:text> Unlocked</xsl:text>
                        </xsl:when>
                        <xsl:when test="@encryption_locked = 'yes'">
                          <xsl:text> Locked</xsl:text>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:if>
                    <xsl:if test="core_storage">
                      <br/>
                      <xsl:text>Core Storage: </xsl:text>
                      <xsl:value-of select="core_storage/name"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="core_storage/size"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="core_storage/status"/>
                    </xsl:if>
                  </li>
                </xsl:for-each>
              </ul>
            </li>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </ul>   
  </xsl:template>

  <xsl:template match="usb">
  
    <h1>USB Information:</h1>
    <ul>
      <xsl:apply-templates mode="device"/>
    </ul>
  
  </xsl:template>
  
  <xsl:template match="firewire">
  
    <h1>Firewire Information:</h1>
    <ul>
      <xsl:apply-templates mode="device"/>
    </ul>
  
  </xsl:template>
  
  <xsl:template match="thunderbolt">
  
    <h1>Thunderbolt Information:</h1>
    <ul>
      <xsl:apply-templates mode="device"/>
    </ul>
  
  </xsl:template>
  
  <xsl:template match="*" mode="device">
  
    <li>
      <p><xsl:value-of select="name"/></p>
      <xsl:if test="manufacturer">
        <p><xsl:value-of select="manufacturer"/></p>
      </xsl:if>
      <xsl:if test="device">
        <ul>
          <xsl:apply-templates select="device" mode="device"/>
        </ul>
      </xsl:if>
    </li>
    
  </xsl:template>

  <xsl:template match="configurationfiles">
  
    <xsl:if test="filesizemismatch or unexpectedfile or SIP/value != 'enabled' or hostsfile/status != 'valid'">
      <h1>Configuration Files:</h1>
      <dl>
        <xsl:for-each select="filesizemismatch">
          <dt><xsl:value-of select="name"/></dt>
          <dd><xsl:value-of select="concat(', File size ', size, ' but expected ', expectedsize)"/></dd>
        </xsl:for-each>
        <xsl:for-each select="unexpectedfile">
          <dt><xsl:value-of select="name"/></dt>
          <dd><xsl:text> - File exists but not expected</xsl:text></dd>
        </xsl:for-each>
        <xsl:if test="SIP/value != 'enabled'">
          <dt>SIP:</dt>
          <dd><xsl:value-of select="SIP/value"/></dd>
        </xsl:if>
        <xsl:if test="hostsfile/status != 'valid'">
          <dt>/etc/hosts file:</dt>
          <dd><xsl:value-of select="hostsfile/status"/></dd>
        </xsl:if>
      </dl>
    </xsl:if>
        
  </xsl:template>

  <xsl:template match="gatekeeper">
  
    <h1>Gatekeeper:</h1>
    <p><xsl:value-of select="."/></p>
      
  </xsl:template>

  <xsl:template match="adware">
  
    <xsl:if test="adwarepath">
      <h1>Adware:</h1>
      <ul>
        <xsl:for-each select="adwarepath">
          <li><xsl:value-of select="."/></li>
        </xsl:for-each>
      </ul>
    </xsl:if>
        
  </xsl:template>

  <xsl:template match="unknownfiles">
  
    <xsl:if test="unknownfile">
      <h1>Unknown Files:</h1>
      <dl>
        <xsl:for-each select="unknownfile">
          <dt><xsl:value-of select="path"/></dt>
          <dd><xsl:value-of select="command"/></dd>
        </xsl:for-each>
      </dl>
    </xsl:if>
        
  </xsl:template>

  <xsl:template match="kernelextensions">
  
    <h1>Kernel Extensions:</h1>
    <dl>
      <xsl:for-each select="bundle">
        <xsl:call-template name="printExtensionBundle"/>
      </xsl:for-each>
    </dl>
        
  </xsl:template>

  <xsl:template name="printExtensionBundle">
  
    <xsl:if test="count(extensions/extension[ignore = 'true']) != count(extensions/extension)">
      <dt><xsl:value-of select="path"/></dt>
      <xsl:for-each select="extensions/extension">
        <dd>
          <xsl:value-of select="concat('[', status, '] ', label, ' (', version, ' - ', date, ')')"/>
        </dd>
      </xsl:for-each>
    </xsl:if>
    
  </xsl:template>

  <xsl:template match="*">
  
    <div class="section">
      <h1><xsl:value-of select="name(.)"/></h1>
    </div>
    
  </xsl:template>

</xsl:stylesheet>
