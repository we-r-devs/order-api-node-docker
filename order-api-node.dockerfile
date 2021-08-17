FROM quay.io/centos7/s2i-base-centos7

# This image provides a Node.JS environment you can use to run your Node.JS
# applications.

EXPOSE 8080

# This image will be initialized with "npm run $NPM_RUN"
# See https://docs.npmjs.com/misc/scripts, and your repo's package.json
# file for possible values of NPM_RUN
# Description
# Environment:
# * $NPM_RUN - Select an alternate / custom runtime mode, defined in your package.json files' scripts section (default: npm run "start").
# Expose ports:
# * 8080 - Unprivileged port used by nodejs application

ENV NODEJS_VERSION=10 \
    NPM_RUN=start \
    NAME=nodejs \
    NPM_CONFIG_PREFIX=$HOME/.npm-global 
ENV LD_LIBRARY_PATH /instantclient_21_1
ENV ORA_IC_URL https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip
ENV S2I_URL https://github.com/openshift/source-to-image/releases/download/v1.0.9/source-to-image-v1.0.9-f9ff77d-linux-amd64.tar.gz


# Set SCL related variables in Dockerfile so that the collection is enabled by default
# Add $HOME/node_modules/.bin to the $PATH, allowing user to make npm scripts
# available on the CLI without using npm's --global installation mode
ENV SUMMARY="Platform for building and running Node.js $NODEJS_VERSION applications" \
    DESCRIPTION="Node.js $NODEJS_VERSION available as container is a base platform for \
building and running various Node.js $NODEJS_VERSION applications and frameworks. \
Node.js is a platform built on Chrome's JavaScript runtime for easily building \
fast, scalable network applications. Node.js uses an event-driven, non-blocking I/O model \
that makes it lightweight and efficient, perfect for data-intensive real-time applications \
that run across distributed devices." \
    PATH=/opt/rh/rh-nodejs$NODEJS_VERSION/root/usr/bin:$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH \
    LD_LIBRARY_PATH=/opt/rh/rh-nodejs$NODEJS_VERSION/root/usr/lib64 \
    X_SCLS=rh-nodejs$NODEJS_VERSION \
    MANPATH=/opt/rh/rh-nodejs$NODEJS_VERSION/root/usr/share/man

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Node.js $NODEJS_VERSION" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,$NAME,$NAME$NODEJS_VERSION" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url="image:///usr/libexec/s2i" \
      com.redhat.dev-mode="DEV_MODE:false" \
      com.redhat.deployments-dir="${APP_ROOT}/src" \
      com.redhat.dev-mode.port="DEBUG_PORT:5858"\
      com.redhat.component="rh-$NAME$NODEJS_VERSION-container" \
      name="centos7/$NAME-$NODEJS_VERSION-centos7" \
      version="$NODEJS_VERSION" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>" \
      help="For more information visit https://github.com/sclorg/s2i-nodejs-container" \
      usage="s2i build <SOURCE-REPOSITORY> quay.io/centos7/$NAME-$NODEJS_VERSION-centos7:latest <APP-NAME>"

ENV STI_SCRIPTS_PATH  /usr/libexec/s2i/

RUN yum install -y wget && \
    wget $ORA_IC_URL && \
    unzip instantclient-basic-linux.x64-21.1.0.0.0.zip && \
    useradd -m -u 10001 docker && usermod docker -aG wheel

RUN yum install -y centos-release-scl-rh && \
    ( [ "rh-${NAME}${NODEJS_VERSION}" != "${NODEJS_SCL}" ] && yum remove -y ${NODEJS_SCL}\* || : ) && \
    INSTALL_PKGS="rh-nodejs${NODEJS_VERSION} rh-nodejs${NODEJS_VERSION}-npm rh-nodejs${NODEJS_VERSION}-nodejs-nodemon nss_wrapper" && \
    ln -s /usr/lib/node_modules/nodemon/bin/nodemon.js /usr/bin/nodemon && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*' && \
    mkdir -p $STI_SCRIPTS_PATH



# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image, including help file.
COPY ./root/ /

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:0 ${APP_ROOT} && chmod -R ug+rwx ${APP_ROOT} && \
    rpm-file-permissions && \
    chown -R 1001:0 $STI_SCRIPTS_PATH && chmod -R ug+rwx $STI_SCRIPTS_PATH

USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage