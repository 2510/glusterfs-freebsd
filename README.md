# glusterfs-freebsd
Build and packaging scripts for GlusterFS on FreeBSD.

Automatic fetch/configure/build/package script for GlusterFS on FreeBSD.
Tested on FreeBSD 9.1-amd64 and 10.1-amd64.

## Prerequisites
Building package requires python2.7.
```
# pkg install python27
```

## Install
To install GlusterFS into local system:
```
# make install
```

## Creating package and install
To create a package:
```
# make package
```
Built package is located at ```package/glusterfs-*.txz```. (* refers to GlusterFS version)
To install this package:
```
# pkg install glusterfs-*.txz
```
