#!/bin/sh

if [ "$NODE_NAME" == "Linux-Debian-4.0-i386" -o "$NODE_NAME" == "Linux-Readynas-ARM" ]
then
  # Create temporary directory
  rm -rf plex_package
  mkdir plex_package

  # Copy over ReadyNAS template.
  cp -r addons_sdk plex_package/
  
  # Go make a tarball.
  pushd $PLX_SRCDIR
  cd ..
  tar cfj PlexMediaServer-$PLX_VERSION.tar.bz2 `basename $PLX_SRCDIR`
  popd
  
  # Move it over to where it should live.
  cd plex_package/addons_sdk/PLEXMEDIASERVER
  test -d files/tmp/rnxtmp || mkdir -p files/tmp/rnxtmp
  mv `dirname $PLX_SRCDIR`/PlexMediaServer-$PLX_VERSION.tar.bz2 files/tmp/rnxtmp/
  
  # Copy language files.
  cp -r language files/etc/frontview/addons/ui/PLEXMEDIASERVER
  
  # Make sure permissions are right.
  chmod 1777 files/tmp
  sudo chown -R root:root files/tmp
  
  # set minimum required RAIDiator version and
  # make the right set of bzip2/bunzip2 available
  if [ $NODE_NAME == Linux-Readynas-ARM ];
  then
    PLX_RAIDIATOR_VERSION="5.3.3"
    mv files/bin_ARM files/bin
    rm -rf files/bin_x86
  else
    PLX_RAIDIATOR_VERSION="4.2.18"
    mv files/bin_x86 files/bin
    rm -rf files/bin_ARM
  fi

  # Replace version names in files.
  for f in addons.conf .PLEXMEDIASERVER_BUILD_SETTINGS PLEXMEDIASERVER_AVAILABLE.xml PLEXMEDIASERVER_CURRENT.xml PLEXMEDIASERVER.xml
  do
    sed -i "s/PLX_VERSION/$PLX_VERSION/" $f
    sed -i "s/PLX_RAIDIATOR_VERSION/$PLX_RAIDIATOR_VERSION/" $f
  done
  
  # Build the ReadyNAS package.
  LD_LIBRARY_PATH=../bin/ ../bin/build_addon

  # And finally, move the package out.
  mv PlexMediaServer_$PLX_VERSION.bin $PLX_OUTDIR/PlexMediaServer-$PLX_VERSION-`uname -m`.bin

  # Clean up.
  cd ../../../
  sudo rm -rf plex_package
fi

