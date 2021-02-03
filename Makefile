PACKAGE := openvpn_defer_auth
PROGRAM := $(PACKAGE).so
CC	:= gcc
PREFIX	:= /usr
INSTALL	:= install
CFLAGS	:= -fPIC
# RPM info
VERSION := 1.3.0
GIT_VERSION := $(shell git rev-parse HEAD)
RPM_ITERATION := 1
FPM_DIR := fpm_tmp_build_dir
LICENSE := GPLv2
UPSTREAM_URL := https://github.com/mozilla-it/openvpn_defer_auth
SUMMARY := OpenVPN plugin to handle deferred authentication requests
DESCRIPTION := Allows authentications for openvpn to be a nonblocking operation\nThis package is built upon commit $(GIT_VERSION)\n

src = $(wildcard *.c)
obj = $(src:.c=.o)

# OSX does a different linker
linker_Darwin = -install_name,$(PROGRAM)
linker_Linux = -soname,$(PROGRAM)
LDFLAGS = -shared -Wl,$(linker_$(shell uname -s))

# OSX calls it lib no matter what
libdir_Darwin = lib
libdir_Linux_x86_64 = lib64
libdir_Linux_i686   = lib
libdir_Linux = $(libdir_Linux_$(shell uname -i))
LIBDIR = $(PREFIX)/$(libdir_$(shell uname -s))

.DEFAULT: all
.PHONY: clean all preflight install installdirs install-strip uninstall rpm

all: preflight
	$(MAKE) $(PROGRAM)

preflight:
	@if [ ! -f openvpn-plugin.h ]; then \
		echo "The openvpn-plugin.h file is missing.  Fetch a copy from the openvpn tarball."; \
		echo "  https://openvpn.net/community-downloads/"; \
		false; \
	fi

$(PROGRAM): $(obj)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(obj) $(PROGRAM)
	rm -f *.rpm
	rm -rf $(FPM_DIR)

installdirs:
	mkdir -p $(DESTDIR)$(LIBDIR)/openvpn/plugins

install: preflight $(PROGRAM)
	@$(MAKE) installdirs
	$(INSTALL) -m755 $(PROGRAM) $(DESTDIR)$(LIBDIR)/openvpn/plugins

uninstall:
	rm -f $(DESTDIR)$(LIBDIR)/openvpn/plugins/$(PROGRAM)

install-strip:
	@$(MAKE) INSTALL='$(INSTALL) -s' install

rpm:
	rm -rf $(FPM_DIR)
	@$(MAKE) DESTDIR=$(FPM_DIR) install-strip
	fpm -f -s dir -t rpm -d openvpn \
	--rpm-dist "$(shell rpmbuild -E '%{?dist}' | sed -e 's#^\.##')" \
	-n $(PACKAGE) -v $(VERSION) --iteration $(RPM_ITERATION) \
	--license $(LICENSE) --url $(UPSTREAM_URL) \
	--rpm-summary "$(SUMMARY)" \
	--description "$$(printf "$(DESCRIPTION)")" \
	-C $(FPM_DIR) usr
