# Build Notes

This plugin is vital for openvpn using deferred authentication.  It is stable as long as the API with openvpn doesn't change.  But since that's rare, the knowledge of how we got here is important to document.

Setting Up
---
This all began with OpenVPN's sample 'defer' plugin code, <https://github.com/OpenVPN/openvpn/blob/fdfbd4441c2225dc69431c57d18291e103c466cf/sample/sample-plugins/defer/simple.c>
Due to a bug in handling multiple deferred plugins, they retired this in 2022-03, so we're back here to adapt to the replacement ```multi-auth.c```:
<https://github.com/OpenVPN/openvpn/blob/976a65346d2193181f4f5664f798e16fcbf43345/sample/sample-plugins/defer/multi-auth.c>

Save the sample 'defer' plugin file:

```curl -s -L -o openvpn_defer_auth.c https://raw.githubusercontent.com/OpenVPN/openvpn/976a65346d2193181f4f5664f798e16fcbf43345/sample/sample-plugins/defer/multi-auth.c```

This is the basis of our script (and note that I'm listing the specific commit, so you can see how up-to-date things are).  Now we start editing it.

Edits
---

This directory contains patches demonstrating how/why we strip down the ```multi-auth.c``` file (named as ```openvpn_defer_auth.c```), and then build it back up.

patch01.diff
* Removes 'config.h' which is neither present nor needed (!?)
* Add an 'UNUSED' macro to highlight variables we don't use.
  * This 'misses' some, but they're obviated in later patches.

patch02.diff
* delete openvpn_plugin_client_constructor_v1 and openvpn_plugin_client_destructor_v1 - we don't use them.
  * This deletes plugin_per_client_context, unused.  We don't retain any per-client info, we just 'pass along' the script's results (see-also: ```auth_control_file```)

patch03.diff
* gut the existing openvpn_plugin_open_v3 useless functionality:
  * This is all the "things the sample is supposed to do" that doesn't help us.
  * remove test_deferred_auth - the whole point is we want deferred ON, not optional.
  * remove the comments at the top of the script specific to the dummy version (no longer applicable)
  * remove everything that reads username/password from env's.  We are a passthrough.
  * remove everything that manages auth_control_file from env's.  We are a passthrough.
    * ... which takes out stdarg.h
  * This takes out do_auth_user_pass...
    * ... which takes out stdbool.h
    * ... which takes out the use of atoi_null0 at the same time
    * ... which then removes np and get_env

patch04.diff
* delete plog logging calls that we don't want, and fix the plugin name.

patch05.diff  -  the beginning of creating
* add 'script_path' to the context, so keep track of what script to call.

patch06.diff
* add a sigchld handler.
  * This doesn't do much for us on its own
  * it's bite-sized, and makes ready for the next patch

patch07.diff
* adapt auth_user_pass_verify into the deferred auth handler
  * This is the actual INTERESTING piece.

With all of these in place, you now have a supremely boring piece of C code.  It does async/deferred auth queries for openvpn, which is pretty essential for human-interactive logins (e.g 2FA).

Revisting
---
You're probably here, years after I wrote this in 2018 (with an update in 2024).  Hi!

Refresh the openvpn-plugin.h file from current.  It will change as the API evolves.  If some function gets deprecated, we need to move off of it.  This repo should be revisited as openvpn matures and ages its API, but that API will age slowly for legacy reasons, I bet.

I'm sure the sample code has changed since https://github.com/OpenVPN/openvpn/commit/aef8a872aa51331f781265fdb6b3c340463637a8  That's not the point of them.

The main goal here is to show you what we stripped out of the sample, and what to add, when you try this again later.

The second goal here is to make the plugin small enough that we are minimally affected by API changes and minimally exposed to bad coding.
