FROM ubuntu
MAINTAINER geodia <georgios.diapoulis@chalmers.se>

ENV LANG C.UTF-8
ENV USER sc
ENV HOME /home/$USER

RUN mkdir -p $HOME
RUN groupadd -r $USER && useradd -r -g $USER $USER

WORKDIR /supercollider

# --- update system
RUN \
  apt-get -qq update && \
  apt-get -y upgrade && \
  apt-get install -y vim wget git unzip screen rsync curl ssh emacs build-essential libgsl-dev libgsl0-dev libjack-jackd2-dev libsndfile1-dev libasound2-dev libavahi-client-dev libicu-dev libreadline6-dev libfftw3-dev libxt-dev pkg-config cmake subversion lame && \
  rm -rf /var/lib/apt/lists/*

WORKDIR temp

# --- build supercollider from source
RUN \
    git clone --recursive https://github.com/supercollider/supercollider.git && \
    cd supercollider && \
    mkdir build && \
    cd build && \
    cmake -L -DCMAKE_BUILD_TYPE="Release" -DBUILD_TESTING=OFF -DENABLE_TESTSUITE=OFF -DSUPERNOVA=OFF -DNATIVE=ON -DSC_EL=OFF -DSC_VIM=OFF -DSC_QT=OFF -DSC_HIDAPI=OFF -DSC_IDE=OFF -DSC_ED=OFF -DINSTALL_HELP=OFF .. && \
    make && \
    make install

# RUN rm -rfd /usr/local/share/SuperCollider/SCClassLibrary/deprecated
RUN mkdir -p /usr/local/share/SuperCollider/Extensions
RUN mkdir -p /root/.local/share/SuperCollider/Extensions


# --- ports
EXPOSE 57110:57110/udp
EXPOSE 57120:57120/udp


# Download sc3plugins source, compile and install
RUN \
    git clone --recursive https://github.com/supercollider/sc3-plugins.git && \
    cd sc3-plugins && \
    mkdir build && cd build && \
    cmake -DSC_PATH=../../supercollider .. && \
    cmake --build . --config Release && \
    # to install the plugins
    cmake --build . --config Release --target install

# --- remove build folder
RUN rm -rfd temp

# SCMIR integration
RUN mkdir -p $HOME/src \
        && cd $HOME/src \
        && wget -q http://web.student.chalmers.se/~geodia/scmir/SCMIR.zip \
        && unzip SCMIR.zip \
        && cd SCMIR/Source \
        && mkdir -p build \
        && cd build \
        && cmake .. \
        && make \
        && make install \
        && mkdir -p $HOME/.local/share/SuperCollider/Extensions/ \
        && cp -r $HOME/src/SCMIR/SCMIRExtensions/ $HOME/.local/share/SuperCollider/Extensions \
        && rm -rf $HOME/src

# --- create runtime workspace
WORKDIR /tmp/out
WORKDIR /tmp/code

CMD ["sclang"]
