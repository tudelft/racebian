#!/bin/bash

# handle arguments

# flags
while test $# != 0
do
    case "$1" in
    --skip-rsync) skip_rsync=t ;;
    --clean-build) clean_build=t ;;
    --debug) debug=t ;;
    esac
    shift
done

# key-value pairs (HOW IS THERE NOT A BUILT IN FOR THIS?)
deploy=$(echo "$@" | awk -F= '{a[$1]=$2} END {print(a["--deploy="])}')

# check for mounts
if ! mountpoint -q $SYSROOT
then
    echo "Rootfs not mounted. Run container with -v rootfs:$SYSROOT"
    exit 1;
fi

if ! mountpoint -q $PACKAGE
then
    echo "Package not mounted. Run container with --mount type=bind,src=/path/to/package/root/,dest=$PACKAGE"
    exit 1;
fi

## update rootfs environment in the volume
# rsync options:
# verbose, recursive through directories, keep symlink, Relative,
# delete missing, discard links outside of transfered directory
if ! [ "$skip_rsync" == t ]
then
    # reason for --copy-unsafe-links: 
    # rsync has no --convert-unsafe-absolute-to-relative option or something
    # so we're gonna have to hard-copy those. But a quick investigation shows
    # that there arent so many (probably actually bugs in the aarch64 gcc
    # library), so this should be fine

    # From the manpage or rsync:
    # --links --copy-unsafe-links
    #       Turn all unsafe symlinks into files and create all safe symlinks.
    rsync -vtr --delete-after --links --copy-unsafe-links \
        --rsh "/usr/bin/sshpass -p $REMOTE_PASSWORD ssh -o StrictHostKeyChecking=no -l $REMOTE_USER" \
        --rsync-path="sudo rsync" \
        --include='/' \
        --include='/lib/' \
        --include='/lib/***' \
        --include='/usr/' \
        --include='/usr/***' \
        --exclude='*' \
        $REMOTE_USER@$REMOTE_IP:/ $SYSROOT \
        || true # do not fail on error, for isntance, because pi is down
fi

# check for empty rootfs (for instance because rsync failed on first run)
if [ -z "$(ls -A $SYSROOT)" ]
then
    echo "Rootfs is mounted, but empty! Do an initial sync by connecting the Pi."
    exit 1;
fi


if [ "$clean_build" == t ]
then
    rm -rf /package/build-$GNU_HOST
fi

mkdir -p /package/build-$GNU_HOST
cd /package/build-$GNU_HOST


# handle build options, then build
CMAKE_EXTRA=
if [ "$debug" == t ]
then
    CMAKE_EXTRA=$CMAKE_EXTRA "-DCMAKE_BUILD_TYPE=Debug"
fi

cmake -DCMAKE_TOOLCHAIN_FILE=$CROSS_TOOLCHAIN -DCMAKE_SYSROOT=$SYSROOT $CMAKE_EXTRA ..
make -j4

# upload if necessary
if [ ! -z $deploy ]
then
    rsync -vrR --delete-after --links --copy-unsafe-links --perms \
        --rsh "/usr/bin/sshpass -p $REMOTE_PASSWORD ssh -o StrictHostKeyChecking=no -l $REMOTE_USER" \
        --rsync-path="sudo rsync" \
        /package/build-$GNU_HOST $REMOTE_USER@$REMOTE_IP:"$deploy"
fi
exit 0
