#
# Makefile for subiquity
#
NAME=subiquity
PYTHONSRC=$(NAME)
PYTHONPATH=$(shell pwd):$(shell pwd)/probert
PROBERTDIR=./probert
PROBERT_REPO=https://github.com/CanonicalLtd/probert
export PYTHONPATH
CWD := $(shell pwd)

CHECK_DIRS := console_conf/ subiquity/ subiquitycore/
PYTHON := python3

ifneq (,$(MACHINE))
	MACHARGS=--machine=$(MACHINE)
endif

.PHONY: run clean check

all: dryrun

install_deps:
	sudo apt-get install -y python3-urwid python3-pyudev python3-nose python3-flake8 \
		python3-yaml python3-coverage python3-dev pkg-config libnl-genl-3-dev \
		libnl-route-3-dev python3-attr python3-distutils-extra python3-requests \
		python3-requests-unixsocket python3-jsonschema

i18n:
	$(PYTHON) setup.py build

dryrun: probert i18n
	$(MAKE) ui-view DRYRUN="--dry-run --bootloader uefi"

ui-view:
	$(PYTHON) -m subiquity $(DRYRUN) $(MACHARGS)

ui-view-serial:
	(TERM=att4424 $(PYTHON) -m subiquity $(DRYRUN) --serial)

lint: flake8

flake8:
	@echo 'tox -e flake8' is preferred to 'make flake8'
	$(PYTHON) -m flake8 $(CHECK_DIRS)

unit:
	echo "Running unit tests..."
	$(PYTHON) -m nose $(CHECK_DIRS)

check: unit

probert:
	@if [ ! -d "$(PROBERTDIR)" ]; then \
		git clone -q $(PROBERT_REPO) $(PROBERTDIR); \
		(cd probert && $(PYTHON) setup.py build_ext -i); \
    fi

clean:
	./debian/rules clean
	rm -f subiquity_test.snap

subiquity_test.snap:
	snapcraft clean
	snapcraft snap --output subiquity_test.snap

%.iso: subiquity_test.snap
	sudo POSM_HOSTNAME=$(POSM_HOSTNAME) ROOTFS=$(ROOTFS) ./scripts/inject-subiquity-snap.sh  ../bionic-live-server-amd64.iso subiquity_test.snap ../$@

.PHONY: flake8 lint
