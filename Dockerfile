# This Dockerfile is used to build an image containing basic stuff to be used as a 
# Jenkins slave build node for intel galileo gen 2.
FROM galileogen2/buildenv:stable

# In case you need proxy
#RUN echo 'Acquire::http::Proxy "http://127.0.0.1:8080";' >> /etc/apt/apt.conf

# Details
ENV maintainer Vipin Madhavanunni <vipmadha@gmail.com>
ENV version 0.1
ENV source "https://github.com/galileogen2/docker-sdk"

# URLs
ENV SDK_FILE_URL https://sourceforge.net/projects/wifizero/files/galileo_sdk_x86_64
ENV OPKG_FILE_URL http://downloads.yoctoproject.org/releases/opkg

# CURRENT VERSION - CHANGE PER BUILD
ENV GALILEO_SDK iot-devkit-glibc-x86_64-image-80211zero-i586-toolchain-1.7.2.sh
ENV SDK_VER 1.7.2
ENV OPKG_SRC opkg-0.3.2.tar.gz
ENV OPKG_VER 0.3.2

# Upgrade packages on image
# Preparations for sshd
run apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openssh-server &&\
    apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

# Install JDK 7 (latest edition)
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openjdk-7-jre-headless &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Install other tools
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" \
    pkg-config cmake libtool libarchive-dev curl libcurl3 libcurl3-dev libgpgme11 libgpgme11-dev &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Install opkg
WORKDIR /tmp/
RUN wget -O $OPKG_SRC $OPKG_FILE_URL/$OPKG_SRC
RUN tar xzf $OPKG_SRC
RUN cd /tmp/opkg-$OPKG_VER &&\
    ./configure --with-static-libopkg --disable-shared --prefix=/usr &&\
    make && \ 
    make install
RUN cd /tmp/ && \
    rm -rf opkg-$OPKG_VER $OPKG_SRC

# Install sdk
WORKDIR /tmp/
RUN wget -O $GALILEO_SDK $SDK_FILE_URL/$GALILEO_SDK/download 
RUN chmod 775 /tmp/$GALILEO_SDK
RUN /bin/bash /tmp/$GALILEO_SDK -y
RUN rm -rf /tmp/$GALILEO_SDK

# Set user jenkins to the image
RUN useradd -m -d /home/jenkins -s /bin/bash jenkins &&\
    echo "jenkins:jenkins" | chpasswd

# Let make jenkins usable
RUN chown -R jenkins:jenkins /build
RUN echo "source /opt/iot-devkit/$SDK_VER/environment-setup-i586-poky-linux" >> /home/jenkins/.bashrc
# Test purpose - direct docker build
RUN echo "source /opt/iot-devkit/$SDK_VER/environment-setup-i586-poky-linux" >> /root/.bashrc

# Standard SSH port
EXPOSE 22

# Default command
CMD ["/usr/sbin/sshd", "-D"]
