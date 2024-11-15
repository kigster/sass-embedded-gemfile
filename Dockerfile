ARG AWS_ACCOUNT_ID

FROM "${AWS_ACCOUNT_ID:-000}".dkr.ecr.us-east-1.amazonaws.com/ecr-public/ubuntu/ubuntu:18.04

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# Shared things that rarely change
# Don't remove all of these, some are required to install gems
# Removing some, however, will slim the image.
RUN touch ~/.profile

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates lsb-release

RUN install -d /usr/share/postgresql-common/pgdg \
  && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt-archive.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    aspell \
    aspell-en \
    autoconf \
    automake \
    bison \
    cmake \
    curl \
    file \
    gcc \
    git-core \
    gstreamer1.0-plugins-base \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    imagemagick \
    libaspell-dev \
    libbison-dev \
    libcurl3-dev \
    libffi-dev \
    libgdbm-dev \
    libjemalloc-dev \
    libmagic-dev \
    libmagickcore-dev \
    libmagickwand-dev \
    libncurses5-dev \
    libpq-dev \
    libqt5webkit5 \
    libqt5webkit5-dev \
    libreadline6-dev \
    libsigsegv2 \
    libsqlite3-dev \
    libssl-dev \
    libtinfo-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    m4 \
    make \
    openssh-client \
    openssl \
    pkg-config \
    poppler-utils \
    # The postgres client must be >= to any version that we use in the app for
    # our db_migrate_spec to work, since it calls pg_dump.
    # https://www.postgresql.org/docs/16/app-pgdump.html
    # > Because pg_dump is used to transfer data to newer versions of
    # > PostgreSQL, the output of pg_dump can be expected to load into
    # PostgreSQL server versions newer than pg_dump's version.
    # pg_dump can also dump from PostgreSQL servers older than its own version.
    # (Currently, servers back to version 9.2 are supported.)
    # However, pg_dump cannot dump from PostgreSQL servers newer than its own
    # major version; it will refuse to even try, rather than risk making an
    # invalid dump.
    postgresql-client-15 \
    python-psycopg2 \
    sudo \
    qt5-default \
    qttools5-dev-tools \
    tzdata \
    zlib1g-dev \
  && cp /usr/share/zoneinfo/US/Pacific /etc/localtime \
  && curl "https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb" -L -O \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ./wkhtmltox_0.12.5-1.bionic_amd64.deb \
  && rm ./wkhtmltox_0.12.5-1.bionic_amd64.deb \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/mozilla\/DST_Root_CA_X3.crt/!mozilla\/DST_Root_CA_X3.crt/g' /etc/ca-certificates.conf \
  && update-ca-certificates

# Install Rust compiler, required for YJIT in Ruby 3.2+
RUN curl --proto '=https' https://sh.rustup.rs -sSf > /tmp/rustup.sh \
      && chmod +x /tmp/rustup.sh \
      && /tmp/rustup.sh -y

# https://matthaliski.com/blog/upgrading-to-rails-7-1-ruby-3-3-and-jemalloc
# Enable JEMALLOC variables. This reduces the memory used by Ruby processes.
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libjemalloc.so"
ENV RUBY_YJIT_ENABLE=1
ENV HOME="/root"

# Download and build Ruby
RUN test -s $HOME/.cargo/env && source $HOME/.cargo/env; \
  mkdir ruby \
  && curl https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.5.tar.gz | tar -zxvf - -C ruby --strip-components=1 \
  && cd ruby \
  && ./configure --disable-install-rdoc --prefix=/usr/local --with-jemalloc --with-yjit \
  && make -j8 \
  && make install \
  && cd .. \
  && rm -rf ruby

RUN gem update --system --no-document

ENV APP_USER=kig

# Create a custom user with UID 1000 and GID 1000
RUN groupadd --gid 1000 ${APP_USER} \
  && useradd --uid 1000 --gid ${APP_USER} --shell /bin/bash --create-home ${APP_USER}

RUN adduser ${APP_USER} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R $APP_USER:$APP_USER "/usr/local"
RUN chown -R $APP_USER:$APP_USER "/home/$APP_USER"

# So that we can add Rust to the $PATH
RUN chmod 711 /root

# Install bottom, a better top (invoke it via btm)
RUN test -s $HOME/.cargo/env && source $HOME/.cargo/env; \
    cargo install bottom -j 8 && \
    cp /root/.cargo/bin/btm /usr/local/bin/btm && \
    cp /root/.cargo/bin/btm /usr/local/bin/bottom && \
    chmod 755 /usr/local/bin/btm && \
    chmod 755 /usr/local/bin/bottom

# Install these basic utilities for basic debugging
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    htop \
    tree \
    locales && \
    locale-gen en_US.UTF-8

RUN chown -R $APP_USER:$APP_USER "/usr/local"
RUN chown -R $APP_USER:$APP_USER "/home/$APP_USER"

#—————————————————————————————————————————————————————————————————————————————————————————————————_
# Application User Environment  
#—————————————————————————————————————————————————————————————————————————————————————————————————_

ENV APP_USER=kig

WORKDIR "/home/$APP_USER"

ENV APP_USER=kig

USER "$APP_USER"

ENV APP_USER=kig

ENV NODE_VERSION=16.14.2

ENV HOME="/home/$APP_USER"
ENV USER="$APP_USER"
ENV NVM_DIR="$HOME/.nvm"

ENV PATH="$PATH:$HOME/.nvm/versions/node/v$NODE_VERSION/bin:/root/.cargo/bin"
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libjemalloc.so"
ENV RUBY_YJIT_ENABLE=1
ENV NVM_DIR="$HOME/.nvm"

RUN mkdir -p "$NVM_DIR"

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash \
  && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && npm i -g yarn

# Install bash-it framework with a powerline prompt
RUN git clone --depth=1 https://github.com/Bash-it/bash-it.git ${HOME}/.bash_it && ${HOME}/.bash_it/install.sh --append-to-config --silent
RUN sed -i'' -E "s/^export BASH_IT_THEME='bobby'/export BASH_IT_THEME='powerline'/g" ${HOME}/.bashrc && \ 
  echo "alias pstree='/usr/bin/pstree -U -t -p -a'" >> ${HOME}/.bashrc && \
  echo "alias dir='ls -alF'" >> ${HOME}/.bashrc

RUN mkdir -p "${HOME}/vendor"

USER "$APP_USER"

COPY .ruby-version "$HOME/.ruby-version"
COPY Gemfile "$HOME/Gemfile"
COPY Gemfile.lock "$HOME/Gemfile.lock"

USER root
RUN chown -R $APP_USER:$APP_USER /home/$APP_USER

USER $APP_USER

# Ruby gems
ENV RUBY_YJIT_ENABLE=1

RUN gem update --system \
    && bundle config set --local path vendor/bundle \
    && bundle install --jobs 4

# Install nvm, and attempt to run yarn install twice to work around a bug in yarn
# where it sometimes fails to download all dependencies on the first run
# RUN source $NVM_DIR/nvm.sh && (yarn install --pure-lockfile --production || yarn install --pure-lockfile --production)

# Record the SHA of the app

CMD ["/bin/bash", "-l"]
