FROM ubuntu:bionic
LABEL maintainer="textadept"

RUN echo "Fetching packages" \
  && apt-get update \
  && DEBIAN_FRONTEND="noninteractive" apt-get install -y -q --no-install-recommends \
    build-essential ca-certificates curl git gnupg mercurial unzip wget zip \
    mingw-w64 \
    clang cmake libssl-dev libxml2-dev llvm-dev lzma-dev uuid-dev \
    libmpc-dev libmpfr-dev libgmp-dev \
    libgtk2.0-dev libncurses5-dev libncursesw5-dev \
    luadoc discount \
  && apt-get clean

COPY luadoc.patch /
RUN echo "Patching LuaDoc" && cd /usr/share/lua/5.1 && patch -p0 < /luadoc.patch

RUN echo "Building osxcross" \
  && wget https://github.com/tpoechtrager/osxcross/archive/748108aec4e3ceb672990df8164a11b0ac6084f7.zip \
  && unzip *.zip && mv osxcross-* /opt/osxcross && rm *.zip \
  && wget https://www.dropbox.com/s/yfbesd249w10lpc/MacOSX10.10.sdk.tar.xz \
  && mv MacOSX* /opt/osxcross/tarballs \
  && cd /opt/osxcross && UNATTENDED=1 SDK_VERSION="10.10" OSX_VERSION_MIN="10.6" ./build.sh
RUN echo "Cleaning up" && rm -rf /opt/osxcross/build /opt/osxcross/tarballs/MacOSX*
ENV PATH="$PATH:/opt/osxcross/target/bin"
