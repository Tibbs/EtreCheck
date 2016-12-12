<?xml version="1.0"?>
<xsl:stylesheet 
  version='1.0' 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:my="http://etresoft.com/etrecheck/byte_units"
  exclude-result-prefixes="my">

  <!-- Convert an EtreCheck report into an HTML representation. -->
  <!-- TODO: Add a parameter for localization and localize with language-specific XML files. -->
  <xsl:output method="html" indent="yes" encoding="UTF-8"/> 
 
  <my:units>
    <unit>B</unit>
    <unit>KB</unit>
    <unit>MB</unit>
    <unit>GB</unit>
    <unit>TB</unit>
    <unit>PB</unit>
  </my:units>
  
  <xsl:variable name="byte_units" select="document('')//my:units/unit"/>

  <my:performance>
    <value key="poor">Poor</value>
    <value key="belowaverage">Below Average</value>
    <value key="good">Good</value>
    <value key="excellent">Excellent</value>
  </my:performance>
  
  <xsl:variable name="performance" select="document('')//my:performance"/>

  <my:batteryhealth>
    <value key="Good">Normal</value>
    <value key="Fair">Replace Soon</value>
    <value key="Poor">Replace Now</value>
  </my:batteryhealth>
  
  <xsl:variable name="batteryhealth" select="document('')//my:batteryhealth"/>

  <xsl:template match='/etrecheck'>
  
    <html>
    
      <head>
        <title>EtreCheck Report</title>
      </head>

      <body>
      
        <!-- TODO: Break this out. -->
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

  <!-- EtreCheck stats. -->
  <xsl:template match="stats">
  
    <xsl:variable name="performancekey" select="performance"/>
    
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:text>EtreCheck version: </xsl:text>
        <xsl:value-of 
          select="/etrecheck/@version"/>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="/etrecheck/@build"/>
        <xsl:text>)</xsl:text>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:text>Report generated: </xsl:text>
        <xsl:value-of select="date"/>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        Download EtreCheck from <a href="https://etrecheck.com" target="_blank">https://etrecheck.com</a>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:text>Runtime: </xsl:text>
        <xsl:value-of select="runtime"/>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:text>Performance: </xsl:text>
        <xsl:value-of select="$performance/value[@key = $performancekey]"/>
      </strong>
    </p>
    
    <p/>
    
    <!-- TODO: This needs to go when the links do. -->
    <p>
      <xsl:call-template name="style"/>
      Click the <span style="color: blue;"><strong>[Support]</strong></span> links for help with non-Apple products.
    </p>
    <p>
      <xsl:call-template name="style"/>
      Click the <span style="color: blue;"><strong>[Details]</strong></span> links for more information about that line.
    </p>

    <p/>
    
  </xsl:template>

  <!-- User-specified problem. -->
  <xsl:template match="problem">
  
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:text>Problem: </xsl:text>
      </strong>
      <xsl:value-of select="problem/type"/>
    </p>

    <!-- Description is optional. -->
    <xsl:if test="problem/description">
      <p>
        <xsl:call-template name="style"/>
        <strong>
          <xsl:text>Description: </xsl:text>
        </strong>
      </p>
      <p>
        <xsl:call-template name="style"/>
        <xsl:value-of select="problem/description"/>
      </p>
      
    </xsl:if>

  </xsl:template>

  <!-- Hardware information. -->
  <!-- TODO: Split this up. -->
  <xsl:template match="hardware">
  
    <xsl:variable name="health" select="batteryinformation/battery/health"/>

    <xsl:variable name="producttype">
      <xsl:choose>
        <xsl:when test="substring(model,1,7) = 'MacBook'">
          <xsl:text>Macnotebooks</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Macdesktops</xsl:text>
        </xsl:otherwise> 
      </xsl:choose>
    </xsl:variable>
    
    <xsl:call-template name="header">
      <xsl:with-param name="text">Hardware Information:</xsl:with-param>
    </xsl:call-template>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="marketingname"/>
    </p>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <strong>
        <a target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of
              select="concat('http://support-sp.apple.com/sp/index?page=cpuspec&amp;cc=',serialcode,'&amp;lang=en')"/>
          </xsl:attribute>
          <xsl:text>[Technical Specifications]</xsl:text>
        </a>
        <xsl:text> - </xsl:text>
        <a target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of
              select="concat('http://support-sp.apple.com/sp/index?page=cpuuserguides&amp;cc=',serialcode,'&amp;lang=en')"/>
          </xsl:attribute>
          <xsl:text>[User Guide]</xsl:text>
        </a>
        <xsl:text> - </xsl:text>
        <a target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of
              select="concat('https://support.apple.com/kb/index?page=servicefaq&amp;geo=United_States&amp;product=',$producttype)"/>
          </xsl:attribute>
          <xsl:text>[Warranty &amp; Service]</xsl:text>
        </a>
      </strong>
    </p>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text> - model: </xsl:text>
      <xsl:value-of select="model"/>
    </p>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="cpucount"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="cpuspeed"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="cputype"/>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="cpu_brand"/>
      <xsl:text>) CPU:</xsl:text>
      <xsl:value-of select="corecount"/>
      <xsl:text>-core</xsl:text>
    </p>

    <!-- TODO: Flag low RAM. -->
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="total"/>
      <xsl:text> RAM</xsl:text>
    </p>

    <!-- TODO: Handle the edge case of VMWare. -->
    <xsl:for-each select="memorybanks/memorybank">
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="indent">20</xsl:with-param>
        </xsl:call-template>
        <xsl:value-of select="name"/>
      </p>
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="indent">30</xsl:with-param>
        </xsl:call-template>
        <xsl:value-of select="size"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="type"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="speed"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="status"/>
      </p>
    </xsl:for-each>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Handoff: </xsl:text>
      <xsl:value-of select="supportshandoff"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Instant Hotspot: </xsl:text>
      <xsl:value-of select="supportsinstanthotspot"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Low energy: </xsl:text>
      <xsl:value-of select="supportslowenergy"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Wireless: </xsl:text>
      <xsl:value-of select="wirelessinterfaces/wirelessinterface/name"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="wirelessinterfaces/wirelessinterface/modes"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Battery: </xsl:text>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">20</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Health = </xsl:text>
      <xsl:value-of select="$batteryhealth/value[@key = $health]"/>
      <xsl:text> - Cycle count = </xsl:text>
      <xsl:value-of select="batteryinformation/battery/cyclecount"/>
    </p>
      
  </xsl:template>
 
  <!-- Video information. -->
  <xsl:template match="video">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Video Information:</xsl:with-param>
    </xsl:call-template>

    <xsl:for-each select="videocard">
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="indent">10</xsl:with-param>
        </xsl:call-template>
        <xsl:value-of select="name"/>
        <xsl:text> - VRAM: </xsl:text>
        <xsl:value-of select="VRAM"/>
      </p>
    
      <!-- Report displays, if any. -->
      <xsl:if test="count(display) &gt; 0">
        <xsl:for-each select="display">
          <p>
            <xsl:call-template name="style">
              <xsl:with-param name="indent">20</xsl:with-param>
            </xsl:call-template>
            <xsl:value-of select="name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="resolution"/>
          </p>
        </xsl:for-each>
      </xsl:if>
    </xsl:for-each>
      
  </xsl:template>

  <!-- System software. -->
  <xsl:template match="systemsoftware">
  
    <!-- TODO: Flag old OS version. -->
    <xsl:call-template name="header">
      <xsl:with-param name="text">System Software:</xsl:with-param>
    </xsl:call-template>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="version"/>
      <xsl:text> - Time since boot: </xsl:text>
    
      <!-- TODO: This looks like a localization problem. -->
      <xsl:value-of select="humanuptime"/>
    </p>

  </xsl:template>

  <!-- Disk information. -->
  <xsl:template match="disk">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Disk Information:</xsl:with-param>
    </xsl:call-template>

    <xsl:for-each select="controller">
      <xsl:for-each select="disk">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="device"/>
          <xsl:text> : (</xsl:text>
          <xsl:value-of select="size"/>
          <xsl:text>) </xsl:text>
          <xsl:value-of select="concat('(', type, ' - TRIM: ', TRIM,')')"/>
          
          <!-- TODO: Flag non-Verified SMART result. -->
          <xsl:if test="SMART != 'Verified'">
            <xsl:value-of select="concat('S.M.A.R.T. Status: ', SMART)"/>
          </xsl:if>
        </p>
        <xsl:if test="count(volumes/volume) &gt; 0">
          <xsl:for-each select="volumes/volume">
            <p>
              <xsl:call-template name="style">
                <xsl:with-param name="indent">20</xsl:with-param>
              </xsl:call-template>
              <xsl:value-of select="name"/>
              <xsl:text> (</xsl:text>
              <xsl:value-of select="device"/>
              <xsl:text>) </xsl:text>
              <xsl:choose>
                <xsl:when test="mount_point">
                  <xsl:value-of select="mount_point"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>&lt;not mounted&gt;</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text> </xsl:text>
              <xsl:if test="type">
                <xsl:text> [</xsl:text>
                <xsl:value-of select="type"/>
                <xsl:text>] </xsl:text>
              </xsl:if>
              <xsl:text>: </xsl:text>
              <xsl:call-template name="bytes">
                <xsl:with-param name="value" select="size"/>
                <xsl:with-param name="k" select="1000"/>
              </xsl:call-template>
              <!-- TODO: Flag low free disk space. -->
              <xsl:if test="free_space">
                <xsl:text> (</xsl:text>
                <xsl:call-template name="bytes">
                  <xsl:with-param name="value" select="free_space"/>
                  <xsl:with-param name="k" select="1000"/>
                </xsl:call-template>
                <xsl:text> free)</xsl:text>
              </xsl:if>
            </p>
            <xsl:if test="@encrypted = 'yes'">
              <p>
                <xsl:call-template name="style">
                  <xsl:with-param name="indent">30</xsl:with-param>
                </xsl:call-template>
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
              </p>
            </xsl:if>
            <xsl:if test="core_storage">
              <p>
                <xsl:call-template name="style">
                  <xsl:with-param name="indent">30</xsl:with-param>
                </xsl:call-template>
                <xsl:text>Core Storage: </xsl:text>
                <xsl:value-of select="core_storage/name"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="core_storage/size"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="core_storage/status"/>
              </p>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
    
  </xsl:template>

  <!-- USB information. -->
  <xsl:template match="usb">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">USB Information:</xsl:with-param>
    </xsl:call-template>
    
    <!-- TODO: Fix this in EtreCheck and here. -->
  
  </xsl:template>
  
  <!-- Firewire information. -->
  <xsl:template match="firewire">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Firewire Information:</xsl:with-param>
    </xsl:call-template>
    
    <!-- TODO: Fix this in EtreCheck and here. -->
  
  </xsl:template>
  
  <!-- Thunderbolt information. -->
  <xsl:template match="thunderbolt">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Thunderbolt Information:</xsl:with-param>
    </xsl:call-template>
    
    <!-- TODO: Fix this in EtreCheck and here. -->
  
  </xsl:template>
  
  <!-- Configuration files. -->
  <xsl:template match="configurationfiles">
  
    <xsl:if test="filesizemismatch or unexpectedfile or SIP/value != 'enabled' or hostsfile/status != 'valid'">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Configuration Files:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:for-each select="filesizemismatch">
        <!-- TODO: Flag these. -->
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text>, File size </xsl:text>
          <xsl:value-of select="size"/>
          <xsl:text> but expected </xsl:text>
          <xsl:value-of select="expectedsize"/>
        </p>
      </xsl:for-each>
      <!-- TODO: Flag these. -->
      <xsl:for-each select="unexpectedfile">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text> - File exists but not expected</xsl:text>
        </p>
      </xsl:for-each>
      <!-- TODO: Flag this. -->
      <xsl:if test="SIP/value != 'enabled'">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:text>SIP: </xsl:text>
          <xsl:value-of select="SIP/value"/>
        </p>
      </xsl:if>
      <xsl:if test="hostsfile/status != 'valid'">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:text>/etc/hosts file: </xsl:text>
          <xsl:value-of select="hostsfile/status"/>
        </p>
      </xsl:if>
    </xsl:if>
        
  </xsl:template>

  <!-- Gatekeeper information. -->
  <xsl:template match="gatekeeper">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Gatekeeper:</xsl:with-param>
    </xsl:call-template>
    
    <!-- TODO: Flag this if necessary. -->
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="."/>
    </p>
      
  </xsl:template>

  <!-- Adware information. -->
  <xsl:template match="adware">
  
    <xsl:if test="adwarepath">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Adware:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:for-each select="adwarepath">
        <!-- TODO: Flag these. -->
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="."/>
        </p>
      </xsl:for-each>
    </xsl:if>

  </xsl:template>
  
  <!-- Unknown files. -->
  <xsl:template match="unknownfiles">
  
    <xsl:if test="unknownfile">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Unknown Files:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:for-each select="unknownfile">
        <!-- TODO: Flag these. -->
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="path"/>
        </p>
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">20</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="command"/>
        </p>
      </xsl:for-each>
    </xsl:if>
        
  </xsl:template>

  <!-- Kernel extensions. -->
  <xsl:template match="kernelextensions">
  
    <xsl:if test="count(bundle//extensions/extension[ignore = 'true']) != count(bundle//extensions/extension)">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Kernel Extensions:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:for-each select="bundle">
        <xsl:if test="count(extensions/extension[ignore = 'true']) != count(extensions/extension)">
          <p>
            <xsl:call-template name="style">
              <xsl:with-param name="indent">10</xsl:with-param>
            </xsl:call-template>
            <strong>
              <xsl:value-of select="path"/>
            </strong>
          </p>
          <xsl:for-each select="extensions/extension">
            <p>
              <xsl:call-template name="style">
                <xsl:with-param name="indent">20</xsl:with-param>
              </xsl:call-template>
              <xsl:apply-templates select="status"/>
              <xsl:text> </xsl:text>
              <xsl:value-of select="label"/>
              <xsl:text> (</xsl:text>
              <xsl:value-of select="version"/>
              <xsl:text> - </xsl:text>
              <xsl:apply-templates select="date"/>
              <xsl:text>)</xsl:text>
            </p>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
        
  </xsl:template>

  <!-- Print startup items. -->
  <xsl:template match="startupitems">
  
    <xsl:if test="count(startupitem) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Startup Items:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:for-each select="startupitem">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="path"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="version"/>
        </p>
      </xsl:for-each>
    </xsl:if>
        
  </xsl:template>

  <!-- TODO: These can all be done more intelligently. -->
  
  <!-- Print system launch agents. -->
  <xsl:template match="systemlaunchagents">
  
    <xsl:if test="count(tasks[@analysis != 'apple']) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">System Launch Agents:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print system launch daemons. -->
  <xsl:template match="systemlaunchdaemons">
  
    <xsl:if test="count(tasks[@analysis != 'apple']) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">System Launch Daemons:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print launch agents. -->
  <xsl:template match="launchagents">
  
    <xsl:if test="count(tasks) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Launch Agents:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print launch daemons. -->
  <xsl:template match="launchdaemons">
  
    <xsl:if test="count(tasks) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Launch Daemons:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user launch agents. -->
  <xsl:template match="userlaunchagents">
  
    <xsl:if test="count(tasks) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">User Launch Agents:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print a launchd task. -->
  <xsl:template match="tasks">
  
    <xsl:for-each select="task">
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="indent">10</xsl:with-param>
        </xsl:call-template>
        <xsl:text></xsl:text>
        <xsl:apply-templates select="@status"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="name"/>
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="date"/>
        <xsl:text>)</xsl:text>
      </p>
    </xsl:for-each>
        
  </xsl:template>

  <!-- Print login items. -->
  <xsl:template match="loginitems">
  
    <xsl:if test="count(loginitem) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">User Login Items:</xsl:with-param>
      </xsl:call-template>
      
      <xsl:apply-templates select="loginitem"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print a single login item. -->
  <xsl:template match="loginitem">
  
    <!-- TODO: Flag login items in the trash. -->
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="type"/>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="path"/>
      <xsl:text>)</xsl:text>
    </p>
        
  </xsl:template>

  <!-- Print internet plugins. -->
  <xsl:template match="internetplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Internet Plug-ins:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user internet plugins. -->
  <xsl:template match="userinternetplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">User Internet Plug-ins:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print audio plugins. -->
  <xsl:template match="audioplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Audio Plug-ins:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user audio plugins. -->
  <xsl:template match="useraudioplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">User Audio Plug-ins:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print iTunes plugins. -->
  <xsl:template match="itunesplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">iTunes Plug-ins:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user iTunes plugins. -->
  <xsl:template match="useritunesplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">User iTunes Plug-ins:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print a single plugin. -->
  <xsl:template match="plugin">
  
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="version"/>
      <xsl:text> (</xsl:text>
      <xsl:apply-templates select="date"/>
      <xsl:text>)</xsl:text>
    </p>
        
  </xsl:template>

  <!-- Print Safari extensions. -->
  <xsl:template match="safariextensions">
  
    <xsl:if test="count(extension) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Safari Extensions:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="extension"/>
    </xsl:if>
        
  </xsl:template>
  
  <!-- Print a single Safari extension. -->
  <xsl:template match="extension">
  
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text> - </xsl:text>
      <xsl:value-of select="author"/>
      <xsl:text> - </xsl:text>
      <a target="_blank">
        <xsl:attribute name="href">
          <xsl:value-of select="url"/>
        </xsl:attribute>
        <strong>
          <xsl:value-of select="url"/>
        </strong>
      </a>
      <xsl:text> (</xsl:text>
      <xsl:apply-templates select="date"/>
      <xsl:text>)</xsl:text>
    </p>
        
  </xsl:template>

  <!-- Print Preference panes. -->
  <xsl:template match="preferencepanes">
  
    <xsl:if test="count(preferencepane) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Preference Panes:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="preferencepane"/>
    </xsl:if>
        
  </xsl:template>
  
  <!-- Print a single Preference pane. -->
  <xsl:template match="preferencepane">
  
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text> - </xsl:text>
      <xsl:value-of select="bundleid"/>
      <xsl:text> - </xsl:text>
      <xsl:apply-templates select="date"/>
      <xsl:text>)</xsl:text>
    </p>
        
  </xsl:template>

  <!-- Print Fonts. -->
  <xsl:template match="fonts">
  
    <!-- TODO: This should only be bad fonts. -->
    <xsl:if test="count(fonts) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Fonts:</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="font"/>
    </xsl:if>
        
  </xsl:template>
  
  <!-- Print a single font. -->
  <xsl:template match="font">
  
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="@status"/>
      <xsl:text>] </xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text> - </xsl:text>
      <xsl:apply-templates select="date"/>
      <xsl:text>)</xsl:text>
    </p>
        
  </xsl:template>

  <!-- Print Time Machine information. -->
  <xsl:template match="timemachine">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Time Machine:</xsl:with-param>
    </xsl:call-template>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Skip System Files: </xsl:text>
      <xsl:value-of select="skipsystemfiles"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Mobile backups: </xsl:text>
      <xsl:value-of select="mobilebackups"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Auto backup: </xsl:text>
      <xsl:value-of select="autobackup"/>
    </p>
    
    <p/>
    
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Volumes being backed up: </xsl:text>
    </p>
    <xsl:apply-templates select="backedupvolumes/volume" mode="timemachine"/>
    
    <p/>
    
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Destinations: </xsl:text>
    </p>
    <xsl:apply-templates select="destinations/destination" mode="timemachine"/>
      
  </xsl:template>

  <!-- Print a Time Machine volume. -->
  <xsl:template match="volume" mode="timemachine">
  
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">20</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text>: Disk size: </xsl:text>
      <xsl:call-template name="bytes">
        <xsl:with-param name="value" select="size"/>
        <xsl:with-param name="k" select="1000"/>
      </xsl:call-template>
      <xsl:text> Space required: </xsl:text>
      <xsl:call-template name="bytes">
        <xsl:with-param name="value" select="sizerequired"/>
        <xsl:with-param name="k" select="1000"/>
      </xsl:call-template>
    </p>
      
  </xsl:template>

  <!-- Print a Time Machine destination. -->
  <xsl:template match="destination" mode="timemachine">
  
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">20</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text> [</xsl:text>
      <xsl:value-of select="type"/>
      <xsl:text>]</xsl:text>
      
      <xsl:if test="@lastused">
        <xsl:text> (Last used)</xsl:text>
      </xsl:if>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Total size: </xsl:text>
      <xsl:call-template name="bytes">
        <xsl:with-param name="value" select="size"/>
        <xsl:with-param name="k" select="1000"/>
      </xsl:call-template>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Total number of backups: </xsl:text>
      <xsl:value-of select="backupcount"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Oldest backup: </xsl:text>
      <xsl:value-of select="oldestbackupdate"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Last backup: </xsl:text>
      <xsl:value-of select="lastbackupdate"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:text>Size of backup disk: </xsl:text>
      <!-- TODO: Add backup analysis. -->
    </p>
    
    <p/>

  </xsl:template>

  <!-- Print a CPU usage information. -->
  <xsl:template match="cpu">
  
    <xsl:if test="count(process) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Top Processes by CPU:</xsl:with-param>
      </xsl:call-template>

      <table>
        <xsl:call-template name="tablestyle"/>
        <xsl:for-each select="process">
          <tr>
            <td>
              <xsl:call-template name="style"/>
              <xsl:call-template name="percentage">
                <xsl:with-param name="value">
                  <xsl:value-of select="cpu"/>
                </xsl:with-param>
              </xsl:call-template>
            </td>
            <td>
              <xsl:call-template name="style"/>
              <xsl:value-of select="name"/>
              <xsl:if test="count &gt; 1">
                <xsl:value-of select="concat('(', count, ')')"/>
              </xsl:if>
            </td>
          </tr>
        </xsl:for-each>
      </table>
    </xsl:if>
      
  </xsl:template>

  <!-- Print a memory usage information. -->
  <xsl:template match="memory">
  
    <xsl:if test="count(process) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Top Processes by Memory:</xsl:with-param>
      </xsl:call-template>

      <table>
        <xsl:call-template name="tablestyle"/>
        <xsl:for-each select="process">
          <tr>
            <td>
              <xsl:call-template name="style"/>
              <xsl:call-template name="bytes">
                <xsl:with-param name="value" select="memory"/>
              </xsl:call-template>
            </td>
            <td>
              <xsl:call-template name="style"/>
              <xsl:value-of select="name"/>
              <xsl:if test="count &gt; 1">
                <xsl:value-of select="concat('(', count, ')')"/>
              </xsl:if>
            </td>
          </tr>
        </xsl:for-each>
      </table>
    </xsl:if>
      
  </xsl:template>

  <!-- Print a virtual memory usage information. -->
  <xsl:template match="vm">
  
    <xsl:call-template name="header">
      <xsl:with-param name="text">Virtual Memory Information:</xsl:with-param>
    </xsl:call-template>

    <table>
      <xsl:call-template name="tablestyle"/>
      <tr>
        <td>
          <xsl:call-template name="style"/>
          <xsl:call-template name="bytes">
            <xsl:with-param name="value" select="availableram"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="style"/>
          Available RAM
        </td>
      </tr>
      <tr>
        <td>
          <xsl:call-template name="style"/>
          <xsl:call-template name="bytes">
            <xsl:with-param name="value" select="freeram"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="style"/>
          Free RAM
          </td>
      </tr>
      <tr>
        <td>
          <xsl:call-template name="style"/>
          <xsl:call-template name="bytes">
            <xsl:with-param name="value" select="usedram"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="style"/>
          Used RAM
        </td>
      </tr>
      <tr>
        <td>
          <xsl:call-template name="style"/>
          <xsl:call-template name="bytes">
            <xsl:with-param name="value" select="filecache"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="style"/>
          Cached files
        </td>
      </tr>
      <tr>
        <td>
          <xsl:call-template name="style"/>
          <xsl:call-template name="bytes">
            <xsl:with-param name="value" select="swapused"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="style"/>
          Swap Used:
        </td>
      </tr>
    </table>
      
  </xsl:template>

  <!-- Print diagnostics information. -->
  <xsl:template match="diagnostics">
  
    <xsl:if test="count(diagnostic) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">Diagnostics Information:</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
      
  </xsl:template>

  <!-- Print a EtreCheck deleted files. -->
  <xsl:template match="etrecheckdeletedfiles">
  
    <xsl:if test="count(deletedfile) &gt; 0">
      <xsl:call-template name="header">
        <xsl:with-param name="text">EtreCheck Deleted Files:</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
      
  </xsl:template>

  <xsl:template name="percentage">
    <xsl:param name="value"/>
    
    <xsl:value-of select="format-number($value div 100.0, '#.#%')"/>
  </xsl:template>

  <xsl:template name="bytes">
    <xsl:param name="value"/>
    <xsl:param name="units">1</xsl:param>
    <xsl:param name="k">1024</xsl:param>
    
    <xsl:choose>
      <xsl:when test="$value &gt; $k">
        <xsl:call-template name="bytes">
          <xsl:with-param name="value" select="$value div $k"/>
          <xsl:with-param name="units" select="$units + 1"/>
          <xsl:with-param name="k" select="$k"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="format-number($value, '#.##')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$byte_units[position() = $units]"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <xsl:template match="date|*[@date]">
    <xsl:value-of select="substring-before(., ' ')"/>
  </xsl:template>
  
  <xsl:template name="style">
    <xsl:param name="indent">0</xsl:param>
  
    <xsl:attribute name="style">
      <xsl:if test="$indent &gt; 0">
        <xsl:text>text-indent: </xsl:text>
        <xsl:value-of select="$indent"/>
        <xsl:text>px;</xsl:text>
      </xsl:if>
      
      <xsl:text>font-size: 12px; font-family: Helvetica, Arial, sans-serif; margin:0;</xsl:text>
    </xsl:attribute>

  </xsl:template>
  
  <xsl:template name="tablestyle">
  
    <xsl:attribute name="style">
      <xsl:text>margin-left: 10px;</xsl:text>
    </xsl:attribute>

  </xsl:template>

  <xsl:template name="header">
    <xsl:param name="text"/>
    
    <p style="font-size: 12px; font-family: Helvetica, Arial, sans-serif; margin: 0; margin-top: 10px;">
      <strong><xsl:value-of select="$text"/></strong>
    </p>
    
  </xsl:template>
  
  <xsl:template match="status|@status">
  
    <span>
      <xsl:attribute name="style">
        <xsl:choose>
          <xsl:when test=". = 'failed'">
            <xsl:text>color: red; font-weight: bold;</xsl:text>
          </xsl:when>
          <xsl:when test=". = 'loaded'">
            <xsl:text>color: rgb(0,0,153); font-weight: bold;</xsl:text>
          </xsl:when>
          <xsl:when test=". = 'running'">
            <xsl:text>color: rgb(51,128,51); font-weight: bold;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>color: rgb(104,104,104); font-weight: bold;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
   
      <xsl:text>[</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>]</xsl:text>
    </span>
    
  </xsl:template>
  
  <xsl:template match="*">
  
    <div class="section">
      <h1><xsl:value-of select="name(.)"/></h1>
    </div>
    
  </xsl:template>

</xsl:stylesheet>
