FROM ubuntu:latest
MAINTAINER Wanseob Lim "email@wanseob.com"

RUN apt-get update \
  && apt-get install -y python3-pip python3-dev git\
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip
RUN git clone https://github.com/Zokrates/pycrypto.git
RUN pip3 install -r pycrypto/requirements.txt
ENV PYTHONPATH "${PYTHONPATH}:/pycrypto"
COPY ./utils/create_challenge_circuit.py ./pycrypto/
WORKDIR pycrypto

ENTRYPOINT ["python3"]
