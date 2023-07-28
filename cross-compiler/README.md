# RPi cross compile solution

## Idea

Create a docker image that does all the compilations and maintains a synched copy of the RPi rootfs.

1. Derive a docker image from debian:bullseye (to get identical environment including glibc2.31)
2. install the cross-compile toolchains in it
3. expose an ENTRYPOINT that handles the building by
  1. keeping an updated copy of the raspberries `lib` and `usr` directies available to the container, for correct includes/linking.
  2. using cmake and make on a specified local package
  3. optionally deploys the build-files to a specified location on the pi

Read further for setup and the eventual build-commands

## Docker image setup

Prerequesites (execute as local user) https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04:
```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce
sudo usermod -aG docker ${USER}
reboot # or open use su - ${USER} for the rest
```

Setup of the image:
```bash
cd cross-compiler
docker buildx build -f Dockerfile.cross --tag=pi-cross .
docker volume create rootfs
```

## Running the build container to build for Raspberry Pi


### First time running

On the first time running the container a lot of environment files are copied from the pi to the (persistent) docker volume we just created.
In subsequent builds they will only be updated when something on the pi changes.
This step can also be skipped manually using the `--slip-rsync` flag.

This means that the pi needs to be connected at least during the first time to do the initial sync.


### Cross compile!

Once setup is complete, this is the magic command:
```bash
sudo sysctl -w net.ipv4.ip_forward=1 # no need, if you did make pi-routing-up
cd package/root/you/want/to/build
docker run \
    -v rootfs:/rootfs \
    --mount type=bind,src=./,dst=/package \
    [optional docker arguments] \
    pi-cross
    [optional container arguments]
```

Optional docker arguments:
```bash
-it --entrypoint=/bin/bash # do not build, but drop into shell. Do not use together with container arguments below!
```

Optional container arguments:
```bash
--skip-rsync                    # do not synchronise rootfs with pi. If no libraries changed and it causes overhead, use this
--clean-build:                  # delete all existing build files before compilation
--debug                         # sets -DCMAKE_BUILD_TYPE=Debug
--deploy=/some/directory/on/pi: # upload the build directory to pi using rsync
```

## Handy Docker commands

Remove all existing containers:
```bash
docker ps -a                    # list all containers (even stopped)
docker rm -f $(docker ps -a -q) # remove all existing containers
docker image ls                 # list images (DO NOT MISTYPE AS images)
docker rmi [image_hash]         # delete image with image_hash
docker volume ls                # list volumes
docker volume rm [volume_name]  # remove volume with volume_name
```