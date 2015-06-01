#!/bin/bash
set -e

# Add various configuration options to the end of `opendkim.conf`.
cat >> /etc/opendkim.conf << EOF;
MinimumKeyBits          1024
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable
Socket                  inet:8891
RequireSafeKeys         false
EOF
