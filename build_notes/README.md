# Build Notes

This plugin is vital for openvpn using deferred authentication.  It is stable as long as the API with openvpn doesn't change.  But since that's rare, the knowledge of how we got here is important to document.

Setting Up
---
This all begins with OpenVPN's sample 'defer' plugin code, <https://github.com/OpenVPN/openvpn/blob/master/sample/sample-plugins/defer/simple.c>.

We'll also refer to its header, <https://github.com/OpenVPN/openvpn/blob/master/include/openvpn-plugin.h.in>.
* Note here that this is a .in file instead of a .h, just to have a file linked.  The place to get the __actual__ header is [the source tarball](https://openvpn.net/index.php/open-source/downloads.html) itself.  __DON'T__ use the .in file to compile with.

The .h is "easy" to fix by hand-fetching it from source.  The hard part is making the .c

Save the sample 'defer' plugin file:

```curl -s -L -o openvpn_defer_auth.c https://raw.githubusercontent.com/OpenVPN/openvpn/master/sample/sample-plugins/defer/simple.c```

This is the basis of our script.  Now we start editing it.

Edits
---

This directory contains patches demonstrating how/why we strip down the ```simple.c``` file (named as ```openvpn_defer_auth.c```), and then build it back up.

patch00.diff
* substitute openvpn_plugin_open_v2 for openvpn_plugin_open_v1
  * v1 is deprecated; this is a bug in the source upstream
  * This has [been reported](https://sourceforge.net/p/openvpn/mailman/message/36357089/), hopefully this patch will go away.

patch01.diff
* In openvpn_plugin_open_v2 and openvpn_plugin_func_v2, strip out all nonessential codepaths / functions they involve.
  * We only need OPENVPN_PLUGIN_AUTH_USER_PASS_VERIFY
  * this takes out tls_verify(), now unused

patch02.diff
* delete openvpn_plugin_client_constructor_v1 and openvpn_plugin_client_destructor_v1 - we don't use them.
  * This deletes plugin_per_client_context, unused.  We don't retain any per-client info, we just 'pass along' the script's results (see-also: ```auth_control_file```)

patch03.diff
* gut the existing openvpn_plugin_open_v2 useless functionality
  * This is all the "things the sample is supposed to do" that doesn't help us.
  * remove the comments at the top of the script specific to the dummy version (no longer applicable)
  * remove test_packet_filter
  * remove test_deferred_auth
  * This guts auth_user_pass_verify...
    * ... which takes out the use of atoi_null0 at the same time
    * ... which then removes np and get_env

patch04.diff
* delete printf's that we don't want.

patch05.diff  -  the beginning of creating
* add 'script_path' to the context, so keep track of what script to call.

patch06.diff
* add a sigchld handler.
  * This doesn't do much for us on its own
  * it's bite-sized, and makes ready for the next patch

patch07.diff
* adapt auth_user_pass_verify into the deferred auth handler
  * This is the actual INTERESTING piece.

patch08.diff
* Add a openvpn_plugin_min_version_required_v1 to require a version 3 API.
  * This is actually kinda stupid.  https://github.com/openvpn/openvpn.git commit 6b2e3b9132e5820cebf4984c86ef742c11587790, 2010-11-29, introduced version 3.  There's no reason to think that someone from that long ago won't have access to version 3 of the API, but, it doesn't hurt, and we're going to add version 3 calls, so let's enforce it.

patch09.diff
* Change openvpn_plugin_{open,func}_v2 to openvpn_plugin_{open,func}_v3
  * This modernizes the API calls to the latest.
  * H/T to https://github.com/fac/auth-script-openvpn for a great exemplar.

With all of these in place, you now have a supremely boring piece of C code.  It does async/deferred auth queries for openvpn, which is pretty essential for multi-user.

Revisting
---
You're probably here, years after I wrote this in 2018.  Hi!

The key to this repo is the openvpn-plugin.h file.  It will change as the API evolves.  If some function gets deprecated, we need to move off of it.  This repo should be revisited as openvpn matures and ages its API, but that API will age slowly for legacy reasons, I bet.

I'm sure the sample code has changed, and these patches no longer apply cleanly towards building our plugin.  That's not the point of them.

The main goal here is to show you what we stripped out of the sample, and what to add, when you try this again later.

The second goal here is to make the plugin small enough that we are minimally affected by API changes.
