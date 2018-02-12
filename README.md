EtreCheck
=========
## EtreCheck 4 will be here soon
Many people have starred and forked EtreCheck the past few years. Thanks for your interest! But I have to ask, what is your interest? EtreCheck 4 will be released this week. If you weren't already following the activity on the xml_new branch, that is what is being used in EtreCheck 4. The new user interface in EtreCheck 4 is not publicly available. Would anyone be interested in that? Or do people just want to see the low-level stuff? I would sincerely like to know. There are parts of EtreCheck 4 that I could release as open source, such as my ESKit utility framework or my RESTKit local REST server. Please let me know. Thanks.

EtreCheck is an easy-to-use [macOS] app to display important details of your system configuration and allow you to copy that information to the Clipboard. EtreCheck automatically removes any personally identifiable information from the output. EtreCheck does not need super-user privileges to run. It will also never ask for your password. It is signed with my Developer ID issued by Apple so it can be installed on systems protected by Apple's Gatekeeper system. Learn more at [https://etrecheck.com][EtreCheck].

This release incorporates a couple of additional open-source projects.

## INPopver
This library reproduces NSPopover on MacOS 10.6. I had to make some significant modifications to get it to work on 10.6 though.

## [smartmontools]
The compiled binary is included in the EtreCheck bundle. Building it is fairly straightforward. The only trick is to build it on 10.6 so it works from 10.6.x (Snow Leopard) through 10.12 (Sierra). I didn't know if building it on 10.12.x would work on older OS versions. I had some hassles with [libcurl] so I didn't want to risk building it on 10.12 as it wouldn't build as a universal binary. The most recent build was done manually on 10.6.x using the commands below.

```
CFLAGS="-arch i386" CXXFLAGS="-arch i386" ./configure
make
cp smartctl smartctl.32
CFLAGS="-arch x86_64" CXXFLAGS="-arch x86_64" ./configure
make
cp smartctl smartctl.64
lipo -create smartctl.32 smartctl.64 -output smartctl
```

[EtreCheck]: https://etrecheck.com
[libcurl]: https://curl.haxx.se/libcurl/
[macOS]: https://www.wikiwand.com/en/List_of_Apple_operating_systems
[smartmontools]: https://www.smartmontools.org/
