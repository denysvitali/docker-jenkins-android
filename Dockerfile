FROM jenkinsci/jenkins:alpine

MAINTAINER denvit
USER root

RUN apk update
RUN apk add curl openjdk7-jre ca-certificates gnupg valgrind shadow python3 py-pip python python-dev
RUN apk --no-cache add ca-certificates wget && \
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub \
&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.27-r0/glibc-2.27-r0.apk \
&& apk add glibc-2.27-r0.apk
RUN apk add docker


#RUN apt-get update
#RUN apt-get install -y \
#    curl \
#    default-jdk \
#    lib32gcc1 \
#    lib32ncurses5 \
#    lib32stdc++6 \
#    lib32z1 \
#    libc6-i386 \
#    unzip \
#    apt-transport-https \
#    ca-certificates \
#    curl \
#    gnupg2 \
#    software-properties-common \
#    locales \
#    valgrind
#
#RUN apt-get -y --no-install-recommends install texlive-latex-base texlive-latex-extra bc

#RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Add Docker
#RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
#RUN add-apt-repository \
#   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
#   $(lsb_release -cs) \
#   stable"
#RUN apt update
#RUN apt install -y docker-ce

ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/tools/:${ANDROID_HOME}/platform-tools

WORKDIR /opt

RUN curl https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip -o sdk-tools.zip
RUN unzip sdk-tools.zip -d /opt/android-sdk

RUN (while sleep 3; do echo "y"; done)| sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-26"


RUN apk add python3 cairo-dev libffi-dev cmake

# Setup Docker
COPY ./docker-setup.sh /
RUN chmod 755 /docker-setup.sh
#RUN /usr/sbin/groupdel docker
RUN chown -R jenkins:jenkins /opt/android-sdk
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
#USER jenkins

# The following SDK packages are needed; the rest are dynamically installed since Android Gradle plugin 2.2
#RUN echo y | android update sdk --no-ui -a --filter extra-android-m2repository,extra-google-google_play_services,extra-google-m2repository,platform-tools

ENV ANDROID_EMULATOR_FORCE_32BIT true

#ADD https://cmake.org/files/LatestRelease/cmake-3.10.1-Linux-x86_64.sh /cmake.sh
#RUN mkdir /opt/cmake
#RUN sh /cmake.sh --prefix=/opt/cmake --skip-license
#RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
#RUN cmake --version

# PANDOC
#RUN wget -O /tmp/pandoc.deb https://github.com/jgm/pandoc/releases/download/2.1.1/pandoc-2.1.1-1-amd64.deb && dpkg -i /tmp/pandoc.deb

ENV PANDOC_VERSION 2.1.1
ENV PANDOC_DOWNLOAD_URL https://github.com/jgm/pandoc/archive/$PANDOC_VERSION.tar.gz
ENV PANDOC_ROOT /usr/local/pandoc
ENV PATH $PATH:$PANDOC_ROOT/bin
RUN apk add --no-cache \
    gmp \
    libffi \
 && apk add --no-cache --virtual build-dependencies \
    --repository "http://nl.alpinelinux.org/alpine/edge/community" \
    ghc \
    cabal \
    linux-headers \
    musl-dev \
    zlib-dev \
    curl \
 && mkdir -p /pandoc-build && cd /pandoc-build \
 && curl -fsSL "$PANDOC_DOWNLOAD_URL" -o pandoc.tar.gz \
 && tar -xzf pandoc.tar.gz && rm -f pandoc.tar.gz \
 && ( cd pandoc-$PANDOC_VERSION && cabal update && cabal install --only-dependencies \
    && cabal configure --prefix=$PANDOC_ROOT \
    && cabal build \
    && cabal copy \
    && cd .. ) \
 && rm -Rf pandoc-$PANDOC_VERSION/ \
 && apk del --purge build-dependencies \
 && rm -Rf /root/.cabal/ /root/.ghc/ \
&& cd / && rm -Rf /pandoc-build


ENTRYPOINT "/docker-setup.sh"
