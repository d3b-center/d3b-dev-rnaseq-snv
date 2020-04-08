FROM ubuntu:18.04
LABEL maintainer="Miguel Brown (brownm28@email.chop.edu)"

ENV STRELKA2_VERSION=2.9.10

RUN apt update -y && apt upgrade -y && apt install -y wget python
RUN wget https://github.com/Illumina/strelka/releases/download/v${STRELKA2_VERSION}/strelka-${STRELKA2_VERSION}.centos6_x86_64.tar.bz2 \
&& tar -xjf strelka-${STRELKA2_VERSION}.centos6_x86_64.tar.bz2 && rm strelka-${STRELKA2_VERSION}.centos6_x86_64.tar.bz2 \
&& apt remove -y wget
