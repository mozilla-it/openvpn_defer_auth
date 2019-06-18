# openvpn_defer_auth

This is a VERY simple openvpn plugin to do deferred authentication requests.

Why do this?
---
When doing MFA (multifactor authentication), it is common to require human interaction.  That introduces a time delay to the authentication process, and openvpn blocks waiting for a reply.  One person being asleep can hang your whole server.

Configuration
---
After installing the ```openvpn_defer_auth.so``` file, add something like this to your openvpn config:

```plugin /usr/lib64/openvpn/plugins/openvpn_defer_auth.so /usr/lib/openvpn/plugins/duo_openvpn.py```

This tells openvpn to use your plugin... and your plugin will fork+exec THAT executable (in this case, a python script) to do the authentication and return success/failure.

Building
---
There is a ```build_notes``` subdirectory explaining the methodology of how to build this plugin.  Essentially, how we get from 'sample code distributed by openvpn' to 'our plugin'.

Troubleshooting
---
The plugin was tested against OpenVPN 2.4.6 initially. The plugin completely fails to run on any older versions.

License
---
This library's source is shipped under a GPLv2 license, the same as OpenVPN 2.

The plugin is greatly derived from their sample code.

To avoid any license/redistribution concerns, I'd love to use a submodule here and say "get it from their repo".  But their git has ```openvpn-plugin.h``` as a pre-autoconf ```.in``` file.  And I COULD have you do it with a lot of autoconf.  But then you'd be building against something that wasn't their shipped code.

As such, I've shipped this repo without the .h file.
