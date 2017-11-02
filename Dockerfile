FROM ubuntu:latest

# build arguments
ARG APP_PACKAGES
ARG APP_LOCALE=en_US
ARG APP_CHARSET=UTF-8
ARG APP_USER=app
ARG APP_USER_DIR=/home/${APP_USER}

# run environment
ENV APP_PORT=${APP_PORT:-3000}
ENV APP_ROOT=${APP_ROOT:-/app}

# exposed ports and volumes
EXPOSE $APP_PORT

# add packages for building NPM modules (required by Meteor)
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl python build-essential locales git ${APP_PACKAGES}
RUN DEBIAN_FRONTEND=noninteractive apt-get autoremove
RUN DEBIAN_FRONTEND=noninteractive apt-get clean

# set the locale (required by Meteor)
RUN locale-gen  ${APP_LOCALE}.${APP_CHARSET}
RUN localedef ${APP_LOCALE}.${APP_CHARSET} -i ${APP_LOCALE} -f ${APP_CHARSET}

# create a non-root user that can write to /usr/local (required by Meteor)
RUN useradd -mUd ${APP_USER_DIR} ${APP_USER}
RUN chown -Rh ${APP_USER} /usr/local
RUN mkdir -p $APP_ROOT/.meteor/local && chown -Rh ${APP_USER} $APP_ROOT
USER ${APP_USER}

# install Meteor
COPY install.meteor.com.sh /tmp/
RUN /tmp/install.meteor.com.sh

# run Meteor from the app directory
WORKDIR ${APP_ROOT}

# private modules
ONBUILD ARG NPM_TOKEN
ONBUILD ENV NODE_ENV="development"
ONBUILD RUN if [ -n $NPM_TOKEN ]; then echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> .npmrc; fi

# pre-installed node_modules in sub-image
ONBUILD COPY package.json package-lock.json $APP_ROOT/
ONBUILD RUN meteor npm install
ONBUILD RUN rm .npmrc

ONBUILD VOLUME ["${APP_ROOT}", "${APP_ROOT}/node_modules/", "${APP_ROOT}/.meteor/local/", "${APP_ROOT}/.git/"]

ENTRYPOINT [ "/usr/local/bin/meteor" ]
