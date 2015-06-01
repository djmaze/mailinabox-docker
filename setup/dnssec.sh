#!/bin/bash

# Create DNSSEC signing keys.

mkdir -p "$STORAGE_ROOT/dns/dnssec";

# TLDs don't all support the same algorithms, so we'll generate keys using a few
# different algorithms. RSASHA1-NSEC3-SHA1 was possibly the first widely used
# algorithm that supported NSEC3, which is a security best practice. However TLDs
# will probably be moving away from it to a a SHA256-based algorithm.
#
# Supports `RSASHA1-NSEC3-SHA1` (didn't test with `RSASHA256`):
#
#  * .info
#  * .me
#
# Requires `RSASHA256`
#
#  * .email
#  * .guide
#
# Supports `RSASHA256` (and defaulting to this)
#
#  * .fund

FIRST=1 #NODOC
for algo in RSASHA1-NSEC3-SHA1 RSASHA256; do
if [ ! -f "$STORAGE_ROOT/dns/dnssec/$algo.conf" ]; then
	if [ $FIRST == 1 ]; then
		echo "Generating DNSSEC signing keys. This may take a few minutes..."
		FIRST=0 #NODOC
	fi

	# Create the Key-Signing Key (KSK) (with `-k`) which is the so-called
	# Secure Entry Point. The domain name we provide ("_domain_") doesn't
	#  matter -- we'll use the same keys for all our domains.
	#
	# `ldns-keygen` outputs the new key's filename to stdout, which
	# we're capturing into the `KSK` variable.
	KSK=$(umask 077; cd $STORAGE_ROOT/dns/dnssec; ldns-keygen -a $algo -b 2048 -k _domain_);

	# Now create a Zone-Signing Key (ZSK) which is expected to be
	# rotated more often than a KSK, although we have no plans to
	# rotate it (and doing so would be difficult to do without
	# disturbing DNS availability.) Omit `-k` and use a shorter key length.
	ZSK=$(umask 077; cd $STORAGE_ROOT/dns/dnssec; ldns-keygen -a $algo -b 1024 _domain_);

	# These generate two sets of files like:
	#
	# * `K_domain_.+007+08882.ds`: DS record normally provided to domain name registrar (but it's actually invalid with `_domain_`)
	# * `K_domain_.+007+08882.key`: public key
	# * `K_domain_.+007+08882.private`: private key (secret!)

	# The filenames are unpredictable and encode the key generation
	# options. So we'll store the names of the files we just generated.
	# We might have multiple keys down the road. This will identify
	# what keys are the current keys.
	cat > $STORAGE_ROOT/dns/dnssec/$algo.conf << EOF;
KSK=$KSK
ZSK=$ZSK
EOF
fi

	# And loop to do the next algorithm...
done
