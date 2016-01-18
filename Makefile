TARBALL=glusterfs-3.6.8.tar.gz

WORK=$(.CURDIR)/work
INSTALLTMP=$(WORK)/install-root
REQUIRED_PACKAGES=bison python27 libtool
PATCHES=glusterfs-3.6.8.patch1 glusterfs-3.6.8.patch2

PACKAGE_NAME=$(TARBALL:.tar.gz=)
EXTRACT_DIR=$(WORK)/$(TARBALL:.tar.gz=)
PACKAGE_DIR=$(.CURDIR)/package
PACKAGE=$(PACKAGE_DIR)/$(PACKAGE_NAME).txz
MANIFEST=$(WORK)/MANIFEST
Q?=@

all: build
.PHONY: clean local-install fetch extract patch prerequisites build package

fetch: $(TARBALL)
$(WORK)/$(TARBALL):
	$(Q)echo "Fetching tarball..."
	$(Q)mkdir -p "$(WORK)"
	$(Q)fetch -o "$(WORK)/$(TARBALL)" "http://download.gluster.org/pub/gluster/glusterfs/3.6/3.6.8/$(TARBALL)"

extract: .extract
.extract: $(WORK)/$(TARBALL)
	$(Q)echo "Extracting tarball..."
	$(Q)mkdir -p "$(WORK)"
	$(Q)tar -Jxf "$(WORK)/$(TARBALL)" -C "$(WORK)"
	$(Q)touch .extract

patch: .patch
.patch: .extract
	$(Q)echo "Patching..."
.for patch in $(PATCHES)
	$(Q)( cd "$(WORK)" ; patch --forward -p0 < "$(.CURDIR)/patches/$(patch)" )
.endfor
	$(Q)touch .patch

prerequisites: .prerequisites
.prerequisites:
.for prerequisite in $(REQUIRED_PACKAGES)
	$(Q)(\
	  pkg info $(p) >/dev/null 2>/dev/null || ( \
	    echo "Installing prerequisite $(p)..." ; \
	    pkg install $(p) || ( echo "Prerequisite not satisfied." ; false ) \
	  ) \
	)
.endfor
	$(Q)touch .prerequisites

build: .build
.build: .patch .prerequisites
	$(Q)echo "Building..."
	$(Q)( cd "$(EXTRACT_DIR)" && ./configure )
	$(Q)rm -f "$(EXTRACT_DIR)/libtool"
	$(Q)ln -s "/usr/local/bin/libtool" "$(EXTRACT_DIR)/libtool"
	$(Q)( cd "$(EXTRACT_DIR)" && make )
	$(Q)touch .build

clean:
	$(Q)rm -rf "$(WORK)"
	$(Q)rm -f .extract .build .patch .local-install

install:
	$(Q)echo "Installing..."
	$(Q)( cd "$(EXTRACT_DIR)" && make install )
	$(Q)echo "Done!"

local-install: .local-install
.local-install: .build
	$(Q)echo "Installing to temporary directory..."
	$(Q)( \
	  mkdir -p "$(INSTALLTMP)" && \
	  cd $(EXTRACT_DIR) && \
	  make install DESTDIR="$(INSTALLTMP)" && \
	  mkdir -p "$(INSTALLTMP)/usr/local/etc/rc.d" && \
	  cp -p "$(.CURDIR)/rc.d/glusterfsd" "$(INSTALLTMP)/usr/local/etc/rc.d" \
	)
	$(Q)touch .local-install

package: $(PACKAGE)
$(PACKAGE): .local-install $(MANIFEST)
	$(Q)echo "Creating package..."
	$(Q)( \
	  mkdir -p $(PACKAGE_DIR) && \
	  cd "$(INSTALLTMP)" && \
	  pkg create -o "$(PACKAGE_DIR)" -M "$(MANIFEST)" -r . $(PACKAGE_NAME) \
	)
	$(Q)echo "Done!"
	$(Q)echo "Package file is at: $(PACKAGE_DIR)/$(PACKAGE_NAME).txz"

$(MANIFEST): .local-install
	$(Q)echo "Building manifest file..."
	$(Q)/usr/local/bin/python2.7 make-manifest.py --root $(INSTALLTMP) --uid root --gid wheel > $(MANIFEST)
