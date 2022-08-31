# Build tree:
# base
#  \-> base-build
#       \-> build-software
#       \-> build-hardware
#  \-> software
#       * copies binaries from build-software
#  \-> hardware
#       * copies binaries from build-hardware
#  \-> hardware-dcsv3
#       * copies binaries from build-hardware
#
# Check <https://docs.mithrilsecurity.io/started/installation> for more info

#######################################
### Base stage: common dependencies ###
#######################################

### base: This image is kept minimal and optimized for size. It has the common runtime dependencies
FROM ubuntu:18.04 AS base

ARG CODENAME=bionic
ARG UBUNTU_VERSION=18.04
ARG SGX_VERSION=2.15.101.1-bionic1
ARG DCAP_VERSION=1.12.101.1-bionic1
ARG SGX_LINUX_X64_SDK=sgx_linux_x64_sdk_2.15.101.1.bin
ARG SGX_LINUX_X64_SDK_URL="https://download.01.org/intel-sgx/sgx-linux/2.15.1/distro/ubuntu18.04-server/"$SGX_LINUX_X64_SDK

ENV DEBIAN_FRONTEND=noninteractive

# -- Install SGX SDK & SGX drivers
RUN \
    # Install temp dependencies
    TEMP_DEPENDENCIES="wget gnupg curl software-properties-common build-essential make" && \
    apt-get update -y && apt-get install -y $TEMP_DEPENDENCIES && \

    # Intall the SGX drivers
    curl -fsSL  https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | apt-key add - && \
    add-apt-repository "deb https://download.01.org/intel-sgx/sgx_repo/ubuntu $CODENAME main" && \
    apt-get update && apt-get install -y \
        sgx-aesm-service=$SGX_VERSION \
        libsgx-ae-epid=$SGX_VERSION \
        libsgx-ae-le=$SGX_VERSION \
        libsgx-ae-pce=$SGX_VERSION \
        libsgx-aesm-ecdsa-plugin=$SGX_VERSION \
        libsgx-aesm-epid-plugin=$SGX_VERSION \
        libsgx-aesm-launch-plugin=$SGX_VERSION \
        libsgx-aesm-pce-plugin=$SGX_VERSION \
        libsgx-aesm-quote-ex-plugin=$SGX_VERSION \
        libsgx-enclave-common=$SGX_VERSION \
        libsgx-epid=$SGX_VERSION \
        libsgx-launch=$SGX_VERSION \
        libsgx-quote-ex=$SGX_VERSION \
        libsgx-uae-service=$SGX_VERSION \
        libsgx-urts=$SGX_VERSION \
        libsgx-ae-qe3=$DCAP_VERSION \
        libsgx-ae-pce=$SGX_VERSION \
        libsgx-pce-logic=$DCAP_VERSION \
        libsgx-qe3-logic=$DCAP_VERSION \
        libsgx-ra-network=$DCAP_VERSION \
        libsgx-ra-uefi=$DCAP_VERSION \
        libsgx-dcap-ql=$DCAP_VERSION \
        libsgx-dcap-quote-verify=$DCAP_VERSION \
        libsgx-dcap-default-qpl=$DCAP_VERSION && \
    mkdir -p /var/run/aesmd && \
    ln -s /usr/lib/x86_64-linux-gnu/libdcap_quoteprov.so.1 /usr/lib/x86_64-linux-gnu/libdcap_quoteprov.so && \

    # Intall the SGX SDK
    wget "https://download.01.org/intel-sgx/sgx-linux/2.15.1/distro/ubuntu18.04-server/"$SGX_LINUX_X64_SDK && \
    chmod u+x $SGX_LINUX_X64_SDK  && \
    echo -e 'no\n/opt' | ./$SGX_LINUX_X64_SDK && \
    rm $SGX_LINUX_X64_SDK && \
    echo 'source /opt/sgxsdk/environment' >> /etc/environment && \

    # Remove temp dependencies
    apt-get remove -y $TEMP_DEPENDENCIES && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt/archives/*

ENV LD_LIBRARY_PATH=/opt/sgxsdk/sdk_libs:/usr/lib:/usr/local/lib:/opt/intel/sgx-aesm-service/aesm/

### base-build: This image has the common build-time dependencies
FROM base AS base-build

ENV GCC_VERSION=8.4.0-1ubuntu1~18.04
ENV RUST_TOOLCHAIN=nightly-2021-11-01
ENV RUST_UNTRUSTED_TOOLCHAIN=nightly-2021-11-01

RUN apt-get update && apt-get install -y \
    unzip \
    lsb-release \
    debhelper \
    cmake \
    reprepro \
    autoconf \
    automake \
    bison \
    build-essential \
    curl \
    dpkg-dev \
    expect \
    flex \
    gdb \
    git \
    git-core \
    gnupg \
    kmod \
    libboost-system-dev \
    libboost-thread-dev \
    libcurl4-openssl-dev \
    libiptcdata0-dev \
    libjsoncpp-dev \
    liblog4cpp5-dev \
    libprotobuf-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    ocaml \
    ocamlbuild \
    pkg-config \
    protobuf-compiler \
    python \
    texinfo \
    uuid-dev \
    wget \
    zip \
    software-properties-common \
    cracklib-runtime \
    gcc-8=$GCC_VERSION \
 && rm -rf /var/lib/apt/lists/*

# -- Custom binutils
RUN cd /root && \
    wget https://download.01.org/intel-sgx/sgx-linux/2.15.1/as.ld.objdump.r4.tar.gz && \
    tar xzf as.ld.objdump.r4.tar.gz && \
    cp -r external/toolset/$BINUTILS_DIST/* /usr/bin/ && \
    rm -rf ./external ./as.ld.objdump.r4.tar.gz

# -- Rust
RUN cd /root && \
    curl 'https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init' --output /root/rustup-init && \
    chmod +x /root/rustup-init && \
    echo '1' | /root/rustup-init --default-toolchain $RUST_TOOLCHAIN && \
    echo 'source /root/.cargo/env' >> /root/.bashrc && \
    /root/.cargo/bin/rustup toolchain install $RUST_UNTRUSTED_TOOLCHAIN && \
    /root/.cargo/bin/rustup component add cargo clippy rust-docs rust-src rust-std rustc rustfmt && \
    /root/.cargo/bin/rustup component add --toolchain $RUST_UNTRUSTED_TOOLCHAIN cargo clippy rust-docs rust-src rust-std rustc rustfmt && \
    /root/.cargo/bin/cargo install xargo && \
    rm /root/rustup-init
ENV PATH="/root/.cargo/bin:$PATH"

##################################
###        bench-env           ###
##################################

from base-build as bench-env

ENV SGX_MODE=HW

# install and configure python and pip
RUN \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa  && \
    apt-get update && \
    apt-get install -y python3.9-dev python3.9-distutils libgl1-mesa-glx && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py && rm get-pip.py && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

# install models dependencies
COPY models/requirements.txt /root
RUN pip install -r /root/requirements.txt && \
    rm /root/requirements.txt && \
    apt-get install -y ffmpeg

#install psql client
RUN apt-get install -y postgresql-client