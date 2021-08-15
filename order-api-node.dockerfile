FROM centos:7
ENV LD_LIBRARY_PATH /instantclient_21_1
ENV ORA_IC_URL https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

RUN yum -y update
RUN yum -y install libaio unzip rlwrap wget

RUN wget $ORA_IC_URL && \
    unzip instantclient-basic-linux.x64-21.1.0.0.0.zip && \
    useradd -m -u 10001 docker && usermod docker -aG wheel
    
USER root
RUN mkdir -p /var/opt/node/apps/$REPO/ && chown -R docker:wheel /var/opt/node/
USER 10001

SHELL ["/bin/bash", "--login", "-c"]

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
RUN nvm install 14.16.0 &&  \
    npm install -g npm@latest
ENV REPO order-api-node
ENV PATH=root/.nvm/versions/node/v14.16.0/bin/:$PATH

#COPY --chown=docker:wheel ./package.json /var/opt/node/apps/"$REPO"/
COPY ./package.json /var/opt/node/apps/"$REPO"/
WORKDIR /var/opt/node/apps/"$REPO"

RUN cd /var/opt/node/apps/"$REPO" && \
    npm install

CMD node dist/index.js