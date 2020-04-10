FROM ubuntu:18.04
LABEL maintainer="Daniel Miller (millerd15@email.chop.edu)"

ENV KRAKEN2_VERSION=v2.0.9-beta
ENV KRAKEN2_DIR=kraken2-2.0.9-beta
ENV KRAKEN2_INS=kraken-install

RUN apt update -y && apt upgrade -y && apt install -y wget build-essential pigz 
RUN wget https://github.com/DerrickWood/kraken2/archive/${KRAKEN2_VERSION}.tar.gz \
&& tar -xzf ${KRAKEN2_VERSION}.tar.gz && rm ${KRAKEN2_VERSION}.tar.gz
RUN cd ${KRAKEN2_DIR} && bash install_kraken2.sh ${KRAKEN2_INS}
RUN cp /${KRAKEN2_DIR}/${KRAKEN2_INS}/kraken2 /bin && cp /${KRAKEN2_DIR}/${KRAKEN2_INS}/kraken2-build /bin && cp /${KRAKEN2_DIR}/${KRAKEN2_INS}/kraken2-inspect /bin
RUN apt remove -y wget
