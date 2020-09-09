FROM ubuntu:bionic
LABEL maintainer="textadept"

# Fetch packages for:
# * Building on Linux
# * Building for Windows
# * Building macOS cross-compiler
# * Building GTK and curses applications
# * Generating Markdown documentation
RUN echo "Fetching packages" \
  && apt-get update \
  && DEBIAN_FRONTEND="noninteractive" apt-get install -y -q --no-install-recommends \
    build-essential ca-certificates curl git gnupg mercurial unzip wget zip \
    mingw-w64 \
    clang cmake libc++-dev libssl-dev libxml2-dev llvm-dev lzma-dev uuid-dev \
    libgtk2.0-dev libncurses5-dev libncursesw5-dev \
    luadoc discount \
  && apt-get clean

# Patch LuaDoc to better control documentation formatting.
COPY luadoc.patch /
RUN echo "Patching LuaDoc" && cd /usr/share/lua/5.1 && patch -p0 < /luadoc.patch

# Build osxcross with newer libc++ headers and without i386 support.
ARG sdk="MacOSX10.13.sdk"
RUN echo "Building osxcross" \
  && wget https://github.com/tpoechtrager/osxcross/archive/748108aec4e3ceb672990df8164a11b0ac6084f7.zip \
  && unzip *.zip && mv osxcross-* /opt/osxcross && rm *.zip \
  && wget https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/${sdk}.tar.xz \
  && tar xJf ${sdk}.tar.xz \
  && cp -r /usr/include/c++/v1 ${sdk}/usr/include/c++ \
  && tar czf /opt/osxcross/tarballs/${sdk}.tar.gz ${sdk} \
  && rm -r ${sdk}* \
  && cd /opt/osxcross \
  && sed -i -e 's/I386_SUPPORTED=1/I386_SUPPORTED=0/;' build.sh \
  && UNATTENDED=1 SDK_VERSION="10.13" OSX_VERSION_MIN="10.6" ./build.sh
RUN echo "Cleaning up" && rm -rf /opt/osxcross/build /opt/osxcross/tarballs/MacOSX*
ENV PATH="$PATH:/opt/osxcross/target/bin"
