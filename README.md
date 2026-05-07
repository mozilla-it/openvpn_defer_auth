# openvpn_defer_auth
---
This is a VERY simple openvpn plugin to do deferred authentication requests.

Why do this?
---
When doing MFA (multifactor authentication), it is common to require human interaction.  That introduces a time delay to the authentication process, and openvpn blocks waiting for a reply.  One person being asleep can hang your whole server.

Configuration
---
After installing the ```openvpn_defer_auth.so``` file, add something like this to your openvpn config:

```
plugin /usr/lib64/openvpn/plugins/openvpn_defer_auth.so /usr/lib/openvpn/plugins/duo_openvpn.py
```

This tells openvpn to use your plugin... and your plugin will fork+exec THAT executable (in the above example case, a 'duo_openvpn' python script) to do the authentication and return success/failure.

Building
---
There is a ```build_notes``` subdirectory explaining the methodology of how to build this plugin.  Essentially, how we get from 'sample code distributed by openvpn' to 'our plugin'.

License
---
This library's source is shipped under a GPLv2 license, the same as OpenVPN 2.
The plugin is greatly derived from their sample code.

Compatibility
---
The plugin was tested against 2.4.6 initially, and has worked through-and-including 2.6.14.




Build and Installation Guide for openvpn_defer_auth
---
This plugin allows OpenVPN to handle authentication requests in a non-blocking mode (deferred authentication).

1. Prerequisites
---
To successfully build the plugin, you will need:

```
    GCC (GNU Compiler Collection)
    Make
    Git (to determine the version from the commit hash)
    OpenVPN Development Headers (usually the openvpn-devel or openvpn-dev package)
```

2. Compilation
---
To create the shared object file (openvpn_defer_auth.so), run:

```
    make
```

3. Installation
---
To install the plugin into the system directories (defaulting to /usr/lib64/openvpn/plugins or /usr/lib/... depending on your architecture):

```
    sudo make install
```

4. Installation with Stripping (Strip)
---
To reduce the binary file size by removing debugging information, use:

```
    sudo make install-strip
```
5. Configuration Options
---
You can modify the installation behavior by passing variables directly to the make command.

```
    Var     -   DefValue    -   Description
    PREFIX  -   /usr        -   Base installation path.
    DESTDIR -   (пусто)     -   Path for staging/temporary installation (useful for packaging).
    CC      -   gcc         -   The C compiler to use.
    CFLAGS  -   fPIC        -   Compiler flags.
```

6. Usage Examples
---
```
# Install to /usr/local instead of /usr:
    sudo make PREFIX=/usr/local install
```

```
# Install to a custom directory for testing:
    make DESTDIR=/tmp/build install
```

7. Additional Commands
---
Create an RPM Package
The fpm utility is used to create RPM packages. Ensure it is installed on your system.

```
    make rpm
```
The package will be generated based on version 1.4.0 and the current Git hash.

8. Uninstall
---
To remove the installed plugin from your system:

```
    sudo make uninstall
```

9. Clean
To remove object files, the compiled plugin, and temporary RPM build files:

```
make clean
```

10. Technical Details (Path Automation)
The Makefile automatically detects the system architecture to select the correct library directory (LIBDIR):

```
    Linux x86_64: /usr/lib64/openvpn/plugins
    Linux i686 / Darwin: /usr/lib/openvpn/plugins
```
