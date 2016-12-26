<?xml version="1.0"?>
<xsl:stylesheet 
  version='1.0' 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:my="http://etresoft.com/etrecheck/byte_units"
  exclude-result-prefixes="my">

  <!-- Convert an EtreCheck report into an HTML representation. -->
  <xsl:output method="html" indent="yes" encoding="UTF-8"/> 
 
  <!-- Show Apple tasks that are normally hidden? Or just show counts? -->
  
  <!-- Hide known Apple failures? -->
  <xsl:param name="showapple" select="false()"/>
  <xsl:param name="hideknownapplefailures" select="true()"/>
  <xsl:param name="language">en</xsl:param>
  
  <!-- Language-specific data. -->
  <xsl:variable name="strings" select="document(concat('html_', $language, '.xml'))/strings"/>
  
  <xsl:variable name="byte_units" select="$strings/byte_units/byte_unit"/>

  <xsl:variable name="performance" select="$strings/performance_rating"/>

  <xsl:variable name="batteryhealth" select="$strings/batteryhealth"/>

  <xsl:variable name="statusattributes" select="$strings/status"/>
  
  <xsl:variable name="severity_explanation" select="$strings/severity_explanation"/>

  <xsl:template match='/etrecheck'>
  
    <html>
    
      <head>
        <title><xsl:value-of select="$strings/title"/></title>
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

  <!-- EtreCheck stats. -->
  <xsl:template match="stats">
  
    <xsl:variable name="performancekey" select="performance"/>
    
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:value-of select="$strings/version"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="/etrecheck/@version"/>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="/etrecheck/@build"/>
        <xsl:text>)</xsl:text>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:value-of select="$strings/report_generated"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="date" mode="full"/>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:value-of select="$strings/download"/>
        <xsl:text> </xsl:text>
        <a href="https://etrecheck.com" target="_blank">https://etrecheck.com</a>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:value-of select="$strings/runtime"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="runtime"/>
      </strong>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:value-of select="$strings/performance"/>
        <xsl:text> </xsl:text>
        
        <!-- Flag bad performance. -->
        <span>
          <xsl:call-template name="style">
            <xsl:with-param name="css">
              <xsl:if test="$performancekey/@severity">          
                <xsl:text>color: red;</xsl:text>
              </xsl:if>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="$performance/value[@key = $performancekey]"/>
        </span>
      </strong>
    </p>
    
    <p/>
    
    <!-- TODO: This needs to go when the links do. -->
    <p>
      <xsl:call-template name="style"/>
      <xsl:copy-of select="$strings/support_help/*|$strings/support_help/text()"/>
    </p>
    <p>
      <xsl:call-template name="style"/>
      <xsl:copy-of select="$strings/details_help/*|$strings/details_help/text()"/>
    </p>

    <p/>
    
  </xsl:template>

  <!-- User-specified problem. -->
  <xsl:template match="problem">
  
    <p>
      <xsl:call-template name="style"/>
      <strong>
        <xsl:value-of select="$strings/problem"/>
        <xsl:text> </xsl:text>
      </strong>
      <xsl:value-of select="problem/type"/>
    </p>

    <!-- Description is optional. -->
    <xsl:if test="problem/description">
      <p>
        <xsl:call-template name="style"/>
        <strong>
          <xsl:value-of select="$strings/description"/>
          <xsl:text> </xsl:text>
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
    
    <xsl:call-template name="header"/>

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
          <xsl:value-of select="$strings/technical_specifications"/>
        </a>
        <xsl:text> - </xsl:text>
        <a target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of
              select="concat('http://support-sp.apple.com/sp/index?page=cpuuserguides&amp;cc=',serialcode,'&amp;lang=en')"/>
          </xsl:attribute>
          <xsl:value-of select="$strings/user_guide"/>
        </a>
        <xsl:text> - </xsl:text>
        <a target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of
              select="concat('https://support.apple.com/kb/index?page=servicefaq&amp;geo=United_States&amp;product=',$producttype)"/>
          </xsl:attribute>
          <xsl:value-of select="$strings/warranty_service"/>
        </a>
      </strong>
    </p>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="name"/>
      <xsl:text> - </xsl:text>
      <xsl:value-of select="$strings/model"/>
      <xsl:text> </xsl:text>
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

    <!-- Flag low RAM. -->
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
        <xsl:with-param name="css">
          <xsl:if test="total/@severity">          
            <xsl:text>color: red; font-weight: bold;</xsl:text>
          </xsl:if>
        </xsl:with-param>
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
      <xsl:value-of select="$strings/handoff"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="supportshandoff"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/instant_hotspot"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="supportsinstanthotspot"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/low_energy"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="supportslowenergy"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/wireless"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="wirelessinterfaces/wirelessinterface/name"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="wirelessinterfaces/wirelessinterface/modes"/>
    </p>
    
    <!-- Flag poor battery health. -->
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
        <xsl:with-param name="css">
          <xsl:if test="batteryinformation/battery/@severity">          
            <xsl:text>color: red; font-weight: bold;</xsl:text>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/battery"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$strings/health"/>
      <xsl:text> = </xsl:text>
      <xsl:value-of select="$batteryhealth/value[@key = $health]"/>
      <xsl:text> - </xsl:text>
      <xsl:value-of select="$strings/cycle_count"/>
      <xsl:text> = </xsl:text>
      <xsl:value-of select="batteryinformation/battery/cyclecount"/>
    </p>
      
  </xsl:template>
 
  <!-- Video information. -->
  <xsl:template match="video">
  
    <xsl:call-template name="header"/>

    <xsl:for-each select="videocard">
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="indent">10</xsl:with-param>
        </xsl:call-template>
        <xsl:value-of select="name"/>
        <xsl:if test="VRAM">
          <xsl:text> - VRAM: </xsl:text>
          <xsl:value-of select="VRAM"/>
        </xsl:if>
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
    <xsl:call-template name="header"/>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="version"/>
      <xsl:text> - </xsl:text>
      <xsl:value-of select="$strings/time_since_boot"/>
      <xsl:text> </xsl:text>
    
      <!-- TODO: This looks like a localization problem. -->
      <xsl:value-of select="humanuptime"/>
    </p>

  </xsl:template>

  <!-- Disk information. -->
  <xsl:template match="disk">
  
    <xsl:call-template name="header"/>

    <xsl:for-each select="controller">
      <xsl:for-each select="disk">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
            <!-- Flag disk failure. -->
            <xsl:with-param name="css">
              <xsl:if test="@severity and @severity_explanation = 'drivefailure'">
                <xsl:text>color: red; font-weight: bold;</xsl:text>
              </xsl:if>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="device"/>
          <xsl:text> : (</xsl:text>
          <xsl:value-of select="size"/>
          <xsl:text>) </xsl:text>
          <xsl:value-of select="concat('(', type, ' - TRIM: ', TRIM,')')"/>
          
          <!-- Report disk errors. -->
          <xsl:if test="errors &gt; 0">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$strings/drive_failure"/>
            <xsl:text> - </xsl:text>
            <xsl:value-of select="$strings/error_count"/>
            <xsl:value-of select="errors"/>
          </xsl:if>
        </p>
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
            <!-- Flag SMART failure. -->
            <xsl:with-param name="css">
              <xsl:if test="@severity and @severity_explanation = 'smartfailure'">
                <xsl:text>color: red; font-weight: bold;</xsl:text>
              </xsl:if>
            </xsl:with-param>
          </xsl:call-template>
          <strong>
            <xsl:if test="@severity">
              <xsl:value-of select="concat('S.M.A.R.T. Status: ', SMART, ' ')"/>
            </xsl:if>
            <a>
              <xsl:attribute name="href">
                <xsl:text>etrecheck://smart/</xsl:text>
                <xsl:value-of select="device"/>
              </xsl:attribute>
              <xsl:value-of select="$strings/show_smart_report"/>
            </a>
          </strong>
        </p>
        <xsl:if test="count(volumes/volume) &gt; 0">
          <xsl:for-each select="volumes/volume">
            <p>
              <xsl:call-template name="style">
                <xsl:with-param name="indent">20</xsl:with-param>
                <!-- Flag disk failure. -->
                <xsl:with-param name="css">
                  <xsl:if test="@severity and @severity_explanation = 'drivefailure'">
                    <xsl:text>color: red; font-weight: bold;</xsl:text>
                  </xsl:if>
                </xsl:with-param>
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
                  <xsl:value-of select="$strings/not_mounted"/>
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
                <span>
                  <xsl:call-template name="style">
                    <!-- Flag low free space. -->
                    <xsl:with-param name="css">
                      <xsl:if test="@severity and @severity_explanation = 'lowdiskspace'">
                        <xsl:text>color: red; font-weight: bold;</xsl:text>
                      </xsl:if>
                    </xsl:with-param>
                  </xsl:call-template>
                  <xsl:text> (</xsl:text>
                  <xsl:call-template name="bytes">
                    <xsl:with-param name="value" select="free_space"/>
                    <xsl:with-param name="k" select="1000"/>
                  </xsl:call-template>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="$strings/free"/>
                  <xsl:text>)</xsl:text>

                  <!-- Flag low free space. -->
                  <xsl:if test="@severity and @severity_explanation = 'lowdiskspace'">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$strings/low"/>
                  </xsl:if>
                </span>
              </xsl:if>
              
              <!-- Report disk errors. -->
              <xsl:if test="errors &gt; 0">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$strings/drive_failure"/>
                <xsl:text> - </xsl:text>
                <xsl:value-of select="$strings/error_count"/>
                <xsl:value-of select="errors"/>
              </xsl:if>
            </p>
            <xsl:if test="@encrypted = 'yes'">
              <p>
                <xsl:call-template name="style">
                  <xsl:with-param name="indent">30</xsl:with-param>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$strings/encrypted"/>
                <xsl:value-of select="@encryption_type"/>
                <xsl:choose>
                  <xsl:when test="@encryption_locked = 'no'">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$strings/unlocked"/>
                  </xsl:when>
                  <xsl:when test="@encryption_locked = 'yes'">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$strings/locked"/>
                  </xsl:when>
                </xsl:choose>
              </p>
            </xsl:if>
            <xsl:if test="core_storage">
              <p>
                <xsl:call-template name="style">
                  <xsl:with-param name="indent">30</xsl:with-param>
                </xsl:call-template>
                <xsl:value-of select="$strings/core_storage"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="core_storage/name"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="core_storage/size"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="core_storage/status"/>
                <!-- TODO: Flag failed encryption status. -->
              </p>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
    
  </xsl:template>

  <!-- USB information. -->
  <xsl:template match="usb">
  
    <xsl:if test="device">
      <xsl:call-template name="header"/>
    
      <xsl:apply-templates select="device" mode="device"/>
    </xsl:if>
      
  </xsl:template>
  
  <!-- Firewire information. -->
  <xsl:template match="firewire">
  
    <xsl:if test="device">
      <xsl:call-template name="header"/>
    
      <xsl:apply-templates select="device" mode="device"/>
    </xsl:if>
  
  </xsl:template>
  
  <!-- Thunderbolt information. -->
  <xsl:template match="thunderbolt">
  
    <xsl:if test="device">
      <xsl:call-template name="header"/>
    
      <xsl:apply-templates select="device" mode="device"/>
    </xsl:if>
  
  </xsl:template>
  
  <!-- Configuration files. -->
  <xsl:template match="configurationfiles">
  
    <xsl:if test="filesizemismatch or unexpectedfile or SIP/value != 'enabled' or hostsfile/status != 'valid'">
      <xsl:call-template name="header"/>
      
      <xsl:for-each select="filesizemismatch">
        <!-- TODO: Flag these. -->
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text>, </xsl:text>
          <xsl:value-of select="$strings/file_size"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="size"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$strings/but_expected"/>
          <xsl:text> </xsl:text>
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
          <xsl:text> - </xsl:text>
          <xsl:value-of select="$strings/file_exists"/>
        </p>
      </xsl:for-each>
      <!-- TODO: Flag this. -->
      <xsl:if test="SIP/value != 'enabled'">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="$strings/sip"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="SIP/value"/>
        </p>
      </xsl:if>
      <xsl:if test="hostsfile/status != 'valid'">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="$strings/hosts_file"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="hostsfile/status"/>
        </p>
      </xsl:if>
    </xsl:if>
        
  </xsl:template>

  <!-- Gatekeeper information. -->
  <xsl:template match="gatekeeper">
  
    <xsl:call-template name="header"/>
    
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
        <!-- Flag Anywhere. -->
        <xsl:with-param name="css">
          <xsl:if test="@severity">
            <xsl:text>color: red; font-weight: bold;</xsl:text>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="."/>
    </p>
      
  </xsl:template>

  <!-- Adware information. -->
  <xsl:template match="adware">
  
    <xsl:if test="adwarepath">
      <xsl:call-template name="header"/>
      
      <xsl:for-each select="adwarepath">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
            <xsl:with-param name="css">color: red; font-weight: bold;</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="."/>
        </p>
      </xsl:for-each>
    </xsl:if>

  </xsl:template>
  
  <!-- Unknown files. -->
  <xsl:template match="unknownfiles">
  
    <xsl:if test="unknownfile">
      <xsl:call-template name="header"/>
      
      <xsl:for-each select="unknownfile">
        <!-- TODO: Flag these. -->
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
            <xsl:with-param name="css">color: red; font-weight: bold;</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="path"/>
        </p>
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">20</xsl:with-param>
            <xsl:with-param name="css">color: red; font-weight: bold;</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="command"/>
        </p>
      </xsl:for-each>
    </xsl:if>
        
  </xsl:template>

  <!-- Kernel extensions. -->
  <xsl:template match="kernelextensions">
  
    <xsl:if test="count(bundle//extensions/extension[ignore = 'true']) != count(bundle//extensions/extension)">
      <xsl:call-template name="header"/>
      
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
      <xsl:call-template name="header"/>
      
      <xsl:for-each select="startupitem">
        <p>
          <xsl:call-template name="style">
            <xsl:with-param name="indent">10</xsl:with-param>
            <xsl:with-param name="css">color: red; font-weight: bold;</xsl:with-param>
          </xsl:call-template>
          <xsl:value-of select="name"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="path"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="version"/>
        </p>
      </xsl:for-each>
      
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="css">margin-left: 10px; color: red; font-weight: bold;</xsl:with-param>
        </xsl:call-template>
        <br/>
        <xsl:value-of select="$strings/severity_explanation/value[@key = 'startupitems_deprecated']"/>
      </p>
      
    </xsl:if>
        
  </xsl:template>

  <!-- TODO: These can all be done more intelligently. -->
  
  <!-- Print system launch agents. -->
  <xsl:template match="systemlaunchagents">
  
    <xsl:call-template name="header"/>
    
    <xsl:apply-templates select="tasks" mode="apple"/>
    
  </xsl:template>
  
  <!-- Print system launch daemons. -->
  <xsl:template match="systemlaunchdaemons">
  
    <xsl:call-template name="header"/>
    
    <xsl:apply-templates select="tasks" mode="apple"/>
        
  </xsl:template>

  <!-- Print Apple tasks. -->
  <xsl:template match="tasks" mode="apple">
  
    <xsl:choose>
      <xsl:when test="$showapple">
        <xsl:apply-templates select="task"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$showapple or count(task[@analysis != 'apple']) &gt; 0 or count(task[@status = 'failed']) &gt; 0">
          <xsl:apply-templates select="task[@analysis != 'apple']"/>
          
          <xsl:choose>
            <xsl:when test="$hideknownapplefailures">
              <xsl:apply-templates select="task[@analysis = 'apple' and @status = 'failed' and @knownfailure != true()]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="task[@analysis = 'apple' and @status = 'failed']"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
                  
        <xsl:variable name="notloaded">
          <xsl:value-of select="count(task[@analysis = 'apple' and @status = 'notloaded'])"/>
        </xsl:variable>
        <xsl:variable name="loaded">
          <xsl:value-of select="count(task[@analysis = 'apple' and @status = 'loaded'])"/>
        </xsl:variable>
        <xsl:variable name="running">
          <xsl:value-of select="count(task[@analysis = 'apple' and @status = 'running'])"/>
        </xsl:variable>

        <xsl:if test="$notloaded &gt; 0">
          <p>
            <xsl:call-template name="style">
              <xsl:with-param name="indent">10</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="$statusattributes/status[@status = 'notloaded']/@status"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$notloaded"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$strings/apple_task"/>
            <xsl:if test="$notloaded &gt; 1">
              <xsl:text>s</xsl:text>
            </xsl:if>
          </p>
        </xsl:if>
        <xsl:if test="$loaded &gt; 0">
          <p>
            <xsl:call-template name="style">
              <xsl:with-param name="indent">10</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="$statusattributes/status[@status = 'loaded']/@status"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$loaded"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$strings/apple_task"/>
            <xsl:if test="$loaded &gt; 1">
              <xsl:text>s</xsl:text>
            </xsl:if>
          </p>
        </xsl:if>
        <xsl:if test="$running &gt; 0">
          <p>
            <xsl:call-template name="style">
              <xsl:with-param name="indent">10</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="@status"/>
            <xsl:apply-templates select="$statusattributes/status[@status = 'running']/@status"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$running"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$strings/apple_task"/>
            <xsl:if test="$running &gt; 1">
              <xsl:text>s</xsl:text>
            </xsl:if>
          </p>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
        
  </xsl:template>

  <!-- Print launch agents. -->
  <xsl:template match="launchagents">
  
    <xsl:if test="count(tasks) &gt; 0">
      <xsl:call-template name="header"/>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print launch daemons. -->
  <xsl:template match="launchdaemons">
  
    <xsl:if test="count(tasks) &gt; 0">
      <xsl:call-template name="header"/>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user launch agents. -->
  <xsl:template match="userlaunchagents">
  
    <xsl:if test="count(tasks) &gt; 0">
      <xsl:call-template name="header"/>
      
      <xsl:apply-templates select="tasks"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print launchd tasks. -->
  <xsl:template match="tasks">
  
    <xsl:for-each select="task">
      <xsl:apply-templates select="."/>
    </xsl:for-each>
        
  </xsl:template>

  <!-- Print a launchd task. -->
  <xsl:template match="task">
  
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
    
    <xsl:if test="@analysis = 'executablemissing'">
      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="indent">20</xsl:with-param>
          <xsl:with-param name="color">red</xsl:with-param>          
          <xsl:with-param name="style">bold</xsl:with-param>          
        </xsl:call-template>
        <xsl:value-of select="$strings/executable_not_found"/>
        <xsl:text> - </xsl:text>
        <xsl:value-of select="executable"/>
      </p>
    </xsl:if>
        
  </xsl:template>

  <!-- Print login items. -->
  <xsl:template match="loginitems">
  
    <xsl:if test="count(loginitem) &gt; 0">
      <xsl:call-template name="header"/>
      
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
      <xsl:call-template name="header"/>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user internet plugins. -->
  <xsl:template match="userinternetplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header"/>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print audio plugins. -->
  <xsl:template match="audioplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header"/>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user audio plugins. -->
  <xsl:template match="useraudioplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header"/>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print iTunes plugins. -->
  <xsl:template match="itunesplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header"/>

      <xsl:apply-templates select="plugin"/>
    </xsl:if>
        
  </xsl:template>

  <!-- Print user iTunes plugins. -->
  <xsl:template match="useritunesplugins">
  
    <xsl:if test="count(plugin) &gt; 0">
      <xsl:call-template name="header"/>

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
      <xsl:call-template name="header"/>

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
      <xsl:call-template name="header"/>

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
      <xsl:call-template name="header"/>

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
  
    <xsl:call-template name="header"/>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/skip_system_files"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="skipsystemfiles"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/mobile_backups"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="mobilebackups"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/auto_backup"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="autobackup"/>
    </p>
    
    <p/>
    
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/volumes_backed_up"/>
      <xsl:text> </xsl:text>
    </p>
    <xsl:apply-templates select="backedupvolumes/volume" mode="timemachine"/>
    
    <p/>
    
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">10</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/destinations"/>
      <xsl:text> </xsl:text>
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
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$strings/disk_size"/>
      <xsl:text> </xsl:text>
      <xsl:call-template name="bytes">
        <xsl:with-param name="value" select="size"/>
        <xsl:with-param name="k" select="1000"/>
      </xsl:call-template>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$strings/space_required"/>
      <xsl:text> </xsl:text>
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
        <xsl:text> </xsl:text>
        <xsl:value-of select="$strings/last_used"/>
      </xsl:if>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/total_size"/>
      <xsl:text> </xsl:text>
      <xsl:call-template name="bytes">
        <xsl:with-param name="value" select="size"/>
        <xsl:with-param name="k" select="1000"/>
      </xsl:call-template>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/number_of_backups"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="backupcount"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/oldest_backup"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="oldestbackupdate"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/last_backup"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="lastbackupdate"/>
    </p>
    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">30</xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$strings/size_of_backup_disk"/>
      <xsl:text> </xsl:text>
      <!-- TODO: Add backup analysis. -->
    </p>
    
    <p/>

  </xsl:template>

  <!-- Print a CPU usage information. -->
  <xsl:template match="cpu">
  
    <xsl:if test="count(process) &gt; 0">
      <xsl:call-template name="header"/>

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
      <xsl:call-template name="header"/>

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
  
    <xsl:call-template name="header"/>

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
          <xsl:value-of select="$strings/available_ram"/>
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
          <xsl:value-of select="$strings/free_ram"/>
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
          <xsl:value-of select="$strings/used_ram"/>
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
          <xsl:value-of select="$strings/cached_files"/>
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
          <xsl:value-of select="$strings/swap_used"/>
        </td>
      </tr>
    </table>
      
  </xsl:template>

  <!-- Print diagnostics information. -->
  <xsl:template match="diagnostics">
  
    <xsl:if test="count(event) &gt; 0">
      <xsl:call-template name="header"/>

      <table>
        <xsl:call-template name="tablestyle"/>
        <xsl:apply-templates select="event"/>
      </table>
    </xsl:if>
    
    <xsl:if test="@severity_explanation = 'diagnoticreport_standardpermissions'">
    
      <xsl:variable name="explanation" select="$strings/severity_explanation/value[@key = 'diagnoticreport_standardpermissions']"/>

      <p>
        <xsl:call-template name="style">
          <xsl:with-param name="css">margin-left: 10px;</xsl:with-param>
        </xsl:call-template>
        <br/>
        <xsl:copy-of select="$explanation/*|$explanation/text()"/>
      </p>
    </xsl:if>
      
  </xsl:template>

  <!-- Print a diagnostics event. -->
  <xsl:template match="event">
  
    <tr>
      <td>
        <xsl:call-template name="style"/>
        <xsl:apply-templates select="date" mode="full"/>
      </td>
      <td>
        <xsl:call-template name="style"/>
        <xsl:apply-templates select="name"/>
      </td>
    </tr>
    
  </xsl:template>
  
  <!-- Print a EtreCheck deleted files. -->
  <xsl:template match="etrecheckdeletedfiles">
  
    <xsl:if test="count(deletedfile) &gt; 0">
      <xsl:call-template name="header"/>
    </xsl:if>
      
  </xsl:template>

  <xsl:template name="percentage">
    <xsl:param name="value"/>
    
    <xsl:value-of select="format-number($value div 100.0, '0.0%')"/>
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
      <xsl:when test="$value = 0">
        <xsl:value-of select="format-number($value, '#')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$byte_units[position() = $units]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="format-number($value, '0.00')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$byte_units[position() = $units]"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <xsl:template match="date|*[@date]">
    <xsl:value-of select="substring-before(., ' ')"/>
  </xsl:template>
  
  <xsl:template match="date|*[@date]" mode="full">
    <xsl:value-of select="substring-before(., ' -')"/>
  </xsl:template>

  <xsl:template match="device" mode="device">
    <xsl:param name="indent">10</xsl:param>

    <p>
      <xsl:call-template name="style">
        <xsl:with-param name="indent">
          <xsl:value-of select="$indent"/>
        </xsl:with-param>
      </xsl:call-template>
      
      <xsl:if test="manufacturer">
        <xsl:value-of select="manufacturer"/>
        <xsl:text> </xsl:text>
      </xsl:if>
      
      <xsl:if test="name">
        <xsl:value-of select="name"/>
      </xsl:if>
    </p>

    <xsl:apply-templates select="device" mode="device">
      <xsl:with-param name="indent">
        <xsl:value-of select="$indent + 10"/>
      </xsl:with-param>
    </xsl:apply-templates>
    
  </xsl:template>
  
  <xsl:template name="style">
    <xsl:param name="indent">0</xsl:param>
    <xsl:param name="color"/>
    <xsl:param name="style"/>
    <xsl:param name="css"/>
  
    <xsl:attribute name="style">
    
      <xsl:if test="$indent &gt; 0">
        <xsl:text>text-indent: </xsl:text>
        <xsl:value-of select="$indent"/>
        <xsl:text>px;</xsl:text>
      </xsl:if>
      
      <xsl:if test="$color">
        <xsl:text>color: </xsl:text>
        <xsl:value-of select="$color"/>
        <xsl:text>;</xsl:text>
      </xsl:if>
      
      <xsl:if test="$style = 'bold'">
        <xsl:text>font-weight: bold;</xsl:text>
      </xsl:if>

      <xsl:if test="$style = 'italic'">
        <xsl:text>font-style: italic;</xsl:text>
      </xsl:if>

      <xsl:text>font-size: 12px; font-family: Helvetica, Arial, sans-serif; margin:0;</xsl:text>
      <xsl:value-of select="$css"/>
      
    </xsl:attribute>

  </xsl:template>
  
  <xsl:template name="tablestyle">
  
    <xsl:attribute name="style">
      <xsl:text>margin-left: 10px;</xsl:text>
    </xsl:attribute>

  </xsl:template>

  <xsl:template name="header">
    
    <xsl:variable name="key" select="local-name(.)"/>
    
    <p style="font-size: 12px; font-family: Helvetica, Arial, sans-serif; margin: 0; margin-top: 10px;">
      <strong>
        <a style="color: black; text-decoration: none;">
          <xsl:attribute name="href">
            <xsl:text>etrecheck://help/</xsl:text>
            <xsl:value-of select="$key"/>
          </xsl:attribute>
          <xsl:value-of select="$strings/headers/value[@key = $key]"/>
          <xsl:text> ⓘ</xsl:text>
        </a>
      </strong>
    </p>
    
  </xsl:template>
  
  <xsl:template match="status|@status">
  
    <xsl:variable name="status" select="."/>
    
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
      <xsl:value-of select="$statusattributes/value[@key = $status]"/>
      <xsl:text>]</xsl:text>
    </span>
    
  </xsl:template>
  
  <xsl:template name="localized_string">
    <xsl:param name="key"/>
    
    <xsl:copy-of select="$string/*[local-name() = $key]"/>
    
  </xsl:template>
  
</xsl:stylesheet>
