# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node for intel galileo gen 2.
FROM ubuntu:trusty
MAINTAINER Vipin Madhavanunni <vipmadha@gmail.com>

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN /bin/sh --version

# In case you need proxy
#RUN echo 'Acquire::http::Proxy "http://127.0.0.1:8080";' >> /etc/apt/apt.conf

# Add locales after locale-gen as needed
# Upgrade packages on image
# Preparations for sshd
run locale-gen en_US.UTF-8 &&\
    apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openssh-server &&\
    apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

#ENV LANG en_US.UTF-8
#ENV LANGUAGE en_US:en
#ENV LC_ALL en_US.UTF-8

# Install JDK 7 (latest edition)
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openjdk-7-jre-headless &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Install Yocto requirement
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" \
    git diffstat texinfo gawk chrpath file python build-essential gcc-multilib vim-common \
    uuid-dev iasl subversion nasm autoconf lzop patchutils &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Set user jenkins to the image
RUN useradd -m -d /home/jenkins -s /bin/sh jenkins &&\
    echo "jenkins:jenkins" | chpasswd

# Yocto build
#WORKDIR /tmp
#COPY BSP/meta-clanton_v1.2.1.1.tar.gz meta-clanton_v1.2.1.1.tar.gz
#RUN tar xvfz meta-clanton_v1.2.1.1.tar.gz
#WORKDIR /tmp/meta-clanton_v1.2.1.1 
#RUN /bin/bash -x setup.sh && /bin/bash oe-init-build-env yocto_build && /bin/bash bitbake image-full

WORKDIR /source
RUN git clone --branch dizzy git://git.yoctoproject.org/poky iotdk
WORKDIR /source/iotdk
RUN git clone --branch dizzy git://git.yoctoproject.org/meta-intel-quark
RUN git clone --branch dizzy git://git.yoctoproject.org/meta-intel-iot-middleware
RUN git clone --branch dizzy git://git.yoctoproject.org/meta-intel-galileo
RUN git clone --branch master git://git.yoctoproject.org/meta-intel-iot-devkit
RUN git clone --branch dizzy http://github.com/openembedded/meta-openembedded.git meta-oe
RUN git clone --branch master git://git.yoctoproject.org/meta-java

WORKDIR /source/iotdk
RUN source oe-init-build-env
#RUN /bin/bash unset OLDPWD && unset HOSTNAME && unset BUILDDIR && . ./oe-init-build-env
WORKDIR /source/iotdk
COPY conf/bblayers.conf build/conf/bblayers.conf
COPY conf/auto.conf build/conf/bblayers.conf
COPY conf/sanity.conf build/conf/sanity.conf
COPY fix/iot-devkit-image.bb meta-intel-iot-devkit/recipes-core/images/iot-devkit-image.bb

RUN source oe-init-build-env && bitbake iot-devkit-prof-dev-image
#RUN /bin/bash unset OLDPWD && unset HOSTNAME && unset BUILDDIR && . ./oe-init-build-env && bitbake core-image-minimal

# Standard SSH port
EXPOSE 22

# Default command
CMD ["/usr/sbin/sshd", "-D"]
