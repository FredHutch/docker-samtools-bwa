# Merge BWA and SAMTOOLS together to allow us to pipe bwa mem to samtools sort
# based on https://hub.docker.com/r/michaelfranklin/bwasamtools
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
  && apt-get install -qq bzip2 gcc g++ make zlib1g-dev wget libncurses5-dev liblzma-dev libbz2-dev pigz libcurl4-openssl-dev \
  && apt-get install -y python3-pip python3-dev python3.8 awscli jq \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3.8 python \
  && pip3 --no-cache-dir install --upgrade pip \
  && rm -rf /var/lib/apt/lists/* \
  && python3 -m pip install --upgrade awscli

RUN python3 -m pip install numpy boto3 pandas pysam
RUN python --version

# Install JDK
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:17-jre $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ENV BWA_VERSION 0.7.17
ENV SAMTOOLS_VERSION 1.12
ENV PICARD_VERSION 3.1.0

RUN cd /opt/ \
    && wget https://github.com/lh3/bwa/releases/download/v${BWA_VERSION}/bwa-${BWA_VERSION}.tar.bz2 \
    && tar -xjf bwa-${BWA_VERSION}.tar.bz2 \
    && rm -f bwa-${BWA_VERSION}.tar.bz2 \
    && cd /opt/bwa-${BWA_VERSION}/ \
    && make

RUN cd /opt/ \
    && wget https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && tar -xjf samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && rm -rf samtools-${SAMTOOLS_VERSION}.tar.bz2  \
    && cd samtools-${SAMTOOLS_VERSION}/ \
    && make && make install

RUN mkdir /opt/picard-${PICARD_VERSION}/ \
    && cd /tmp/ \
    && wget --no-check-certificate https://github.com/broadinstitute/picard/releases/download/${PICARD_VERSION}/picard.jar \
    && mv picard.jar /opt/picard-${PICARD_VERSION}/ \
    && ln -s /opt/picard-${PICARD_VERSION} /opt/picard \
    && ln -s /opt/picard-${PICARD_VERSION} /usr/picard

# Add executable paths to /usr/gitc/
RUN mkdir /usr/gitc/ \
    && ln -s /opt/samtools-${SAMTOOLS_VERSION}/samtools /usr/gitc/ \
    && ln -s /opt/bwa-${BWA_VERSION}/bwa /usr/gitc/ \
    && ln -s /opt/picard-${PICARD_VERSION}/picard.jar /usr/gitc/
  
ENV PATH="/opt/bwa-${BWA_VERSION}/:/opt/samtools-${SAMTOOLS_VERSION}/:${PATH}:/opt/picard-${PICARD_VERSION}/:${PATH}"