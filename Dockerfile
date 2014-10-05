FROM ubuntu:14.04

# install required binaries/scripts
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install curl build-essential git -y
RUN curl -L http://cpanmin.us | perl - App::cpanminus

# required for testing
RUN cpanm Test::Trap
RUN cpanm File::Slurp

# so git runs smoothly
RUN git config --global user.name "Test User"
RUN git config --global user.email "testuser@endot.org"
