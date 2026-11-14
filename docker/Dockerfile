# Thin layer on top of the official image.
#
# The official image only ships stable releases. To test plugins against an
# upcoming release (e.g. 6.0.0-rc1) we swap /usr/src/matomo for the requested
# version. The entrypoint copies /usr/src/matomo into /var/www/html on first
# start, so everything else works exactly like the official image.
#
# Leave MATOMO_VERSION empty to use whatever the base image ships.

ARG BASE_IMAGE=matomo:5-apache
FROM ${BASE_IMAGE}

ARG MATOMO_VERSION=

RUN set -eux; \
	current="$(sed -n "s/.*const VERSION = '\(.*\)';.*/\1/p" /usr/src/matomo/core/Version.php)"; \
	if [ -z "$MATOMO_VERSION" ] || [ "$MATOMO_VERSION" = "$current" ]; then \
		echo "Using Matomo $current from base image"; \
		exit 0; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends gnupg dirmngr; \
	cd /tmp; \
	curl -fsSL -o matomo.tar.gz "https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz"; \
	curl -fsSL -o matomo.tar.gz.asc "https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys F529A27008477483777FC23D63BB30D0E5D2C749; \
	gpg --batch --verify matomo.tar.gz.asc matomo.tar.gz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" matomo.tar.gz.asc /usr/src/matomo; \
	tar -xzf matomo.tar.gz -C /usr/src/; \
	rm matomo.tar.gz; \
	apt-get purge -y --auto-remove gnupg dirmngr; \
	rm -rf /var/lib/apt/lists/*
