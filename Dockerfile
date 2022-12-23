FROM ubuntu

LABEL MAINTAINER="Richard Holzeis <richard@holzeis.me>"
LABEL org.opencontainers.image.authors="richard@holzeis.me"
LABEL org.opencontainers.image.source="https://github.com/holzeis/signet"

ARG VERSION=22.0

ENV FILENAME bitcoin-${VERSION}-aarch64-linux-gnu.tar.gz
ENV DOWNLOAD_URL https://bitcoincore.org/bin/bitcoin-core-${VERSION}/${FILENAME}

RUN apt update \
  && apt install wget -y \
  && wget $DOWNLOAD_URL \
  && tar xzvf /$FILENAME \
  && mkdir /root/.bitcoin \
  && mv /bitcoin-${VERSION}/bin/* /usr/local/bin/ \
  && rm -rf /bitcoin-${VERSION}/ \
  && rm -rf /$FILENAME \
  && apt remove wget -y

EXPOSE 38333

RUN apt install jq -y \
  && apt install git -y \
  && apt install python3 -y \
  && apt install bc -y \
  && git clone https://github.com/bitcoin/bitcoin.git

RUN apt install rsync -y

COPY setup.sh /setup.sh

RUN chmod +x /setup.sh \
  && ./setup.sh

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD /run.sh