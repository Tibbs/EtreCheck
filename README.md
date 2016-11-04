EtreCheck
=========
EtreCheck is an easy-to-use little app to display the important details of your system configuration and allow you to copy that information to the Clipboard. EtreCheck automatically removes any personally identifiable information from the output. EtreCheck does not need super-user privileges to run. It will also never ask for your password. It is signed with my Developer ID issued by Apple so it can be installed on systems protected by Apple's Gatekeeper system.

This release incorporates a couple of additional open-source projects.

## INPopver
This library reproduces NSPopover on 10.6. I had to make some significant modifications to get it to work on 10.6 though.

## smartmontools
The compiled binary is included in the EtreCheck bundle. Compiling the binary is straightforward. The only trick is to build it on 10.6 so it works from 10.6-10.12. I don't know if building it on 10.12 would still work. I had some hassles with libcurl so I didn't want to risk it. It wouldn't build with as universal binary, so I had to do it manually.

```
CFLAGS="-arch i386" CXXFLAGS="-arch i386" ./configure
make
cp smartctl smartctl.32
CFLAGS="-arch x86_64" CXXFLAGS="-arch x86_64" ./configure
make
cp smartctl smartctl.64
lipo -create smartctl.32 smartctl.64 -output smartctl
```
