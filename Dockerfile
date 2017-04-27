# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node for intel galileo gen 2.
FROM ubuntu:trusty
MAINTAINER Vipin Madhavanunni <vipmadha@gmail.com>

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

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install JDK 7 (latest edition)
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openjdk-7-jre-headless &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Install Yocto requirement
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" \
    git diffstat texinfo gawk chrpath file python build-essential gcc-multilib vim-common \
    uuid-dev iasl subversion nasm autoconf lzop patchutils parted wget screen \
    vim vim-common bash-completion &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" \
    language-pack-en-base &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Set locales
RUN locale-gen en_US $LANG
RUN dpkg-reconfigure --frontend=noninteractive locales
RUN update-locale LANGUAGE=$LANG

# Set git
RUN git config --global user.name "Vipin Madhavanunni"
RUN git config --global user.email "vipmadha@gmail.com"

# build dir
VOLUME /build

# Install sdk
WORKDIR /tmp/
#COPY sdk/iot-devkit-glibc-x86_64-image-WiFiZero-i586-toolchain-1.7.2.sh /tmp/
RUN wget -O iot-devkit-glibc-x86_64-image-WiFiZero-i586-toolchain-1.7.2.sh https://sourceforge.net/projects/wifizero/files/galileo_sdk_x86_64/iot-devkit-glibc-x86_64-image-WiFiZero-i586-toolchain-1.7.2.sh/download 
RUN chmod 775 /tmp/iot-devkit-glibc-x86_64-image-WiFiZero-i586-toolchain-1.7.2.sh
RUN /bin/bash -x /tmp/iot-devkit-glibc-x86_64-image-WiFiZero-i586-toolchain-1.7.2.sh -y
RUN rm -rf /tmp/iot-devkit-glibc-x86_64-image-WiFiZero-i586-toolchain-1.7.2.sh

# Set user jenkins to the image
RUN useradd -m -d /home/jenkins -s /bin/bash jenkins &&\
    echo "jenkins:jenkins" | chpasswd
# Let make jenkins usable
RUN chown -R jenkins:jenkins /build
RUN echo "source /opt/iot-devkit/1.7.2/environment-setup-i586-poky-linux" >> /home/jenkins/.bashrc
# Test purpose
RUN echo "source /opt/iot-devkit/1.7.2/environment-setup-i586-poky-linux" >> /root/.bashrc

# Standard SSH port
EXPOSE 22

# Default command
CMD ["/usr/sbin/sshd", "-D"]
