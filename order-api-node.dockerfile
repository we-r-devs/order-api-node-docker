FROM centos:7
ENV LD_LIBRARY_PATH /instantclient_21_1

RUN yum -y update
RUN yum -y install libaio unzip rlwrap

ADD instantclient-basic-linux.x64-21.1.0.0.0.zip /

RUN unzip instantclient-basic-linux.x64-21.1.0.0.0.zip && \
    useradd -m -u 10001 docker && usermod docker -aG wheel
USER root
RUN mkdir -p /var/opt/node/apps/$REPO/ && chown -R docker:wheel /var/opt/node/
USER 10001

SHELL ["/bin/bash", "--login", "-c"]

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
RUN nvm install 14.16.0 &&  \
    npm install -g npm@latest
ARG REPO_ARG
ENV REPO $REPO_ARG
ENV PATH=root/.nvm/versions/node/v14.16.0/bin/:$PATH

COPY --chown=docker:wheel ./"$REPO"/ /var/opt/node/apps/"$REPO"/
WORKDIR /var/opt/node/apps/"$REPO"
ARG env_filename
ENV environment $env_filename

RUN rm -f /var/opt/node/apps/"$REPO"/.env && \
    cp .env.change.me $environment && \
    cd /var/opt/node/apps/"$REPO" && \
    npm install && \
    npm run build

CMD node dist/index.js