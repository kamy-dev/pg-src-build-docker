# Dockerfile: build PostgreSQL from source with PL/Python using multi stage builds
# ===============================
# 1. Development stage
# ===============================
FROM ubuntu:22.04 AS dev
ARG DEBIAN_FRONTEND=noninteractive

# Install build deps (minimal + PL/Python deps)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential git wget sudo ca-certificates curl pkg-config \
    flex bison autoconf automake libtool gettext \
    libreadline-dev zlib1g-dev libssl-dev \
    libxml2-dev libxml2-utils libxslt1-dev libbz2-dev liblzma-dev libncursesw5-dev \
    libicu-dev sgml-base docbook-xml docbook-xsl xsltproc sgml-data\
    python3 python3-dev python3-venv python3-pip libpython3-dev postgresql-contrib \
    locales \
 && rm -rf /var/lib/apt/lists/*

# Update CA certificates and configure Git
RUN update-ca-certificates \
 && git config --global http.sslVerify true

# Create postgres user and directories
RUN useradd -m postgres || true \
  && mkdir -p /opt/pgsql /pgsql /wal \
  && chown -R postgres:postgres /pgsql /wal \
  && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

WORKDIR /usr/local/src
# Clone PostgreSQL repository with fallback options
RUN git clone --depth 1 https://git.postgresql.org/git/postgresql.git || \
    git -c http.sslVerify=false clone --depth 1 https://git.postgresql.org/git/postgresql.git

WORKDIR /usr/local/src/postgresql
ENV PYTHON=python3

RUN mkdir build_dir \
    && cd build_dir \
    && ../configure \
          --prefix=/opt/pgsql \
          --with-openssl \
          --with-libxml \
          --with-libxslt \
          --with-python \
    && make world \
    && make install-world

VOLUME ["/pgsql","/wal"]
EXPOSE 5432

USER postgres

CMD ["/bin/bash", "-c", "\
  if [ ! -d /pgsql/PG_VERSION ]; then \
     /opt/pgsql/bin/initdb --no-locale --encoding=utf8 -U postgres -D /pgsql -X /wal; \
  fi && \
  exec /opt/pgsql/bin/postgres -D /pgsql \
       -c unix_socket_directories='/tmp'"]

# ===============================
# 2. Production stage
# ===============================
FROM ubuntu:22.04 AS prod

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libreadline8 zlib1g libssl3 libxslt1.1 libbz2-1.0 liblzma5 libncursesw6 locales \
      git wget sudo \
      python3 libpython3-dev postgresql-contrib \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV PYTHON=python3

COPY --from=dev /opt/pgsql /opt/pgsql

RUN useradd -m postgres \
 && mkdir -p /pgsql /wal \
 && chown -R postgres:postgres /pgsql /wal \
 && locale-gen en_US.UTF-8

VOLUME ["/pgsql","/wal"]
EXPOSE 5432

USER postgres
WORKDIR /

# Initialize DB when container latest (if /pgsql empty) and then start
# Using a shell to check if data directory is empty
CMD ["/bin/bash", "-c", "if [ ! -d /pgsql/PG_VERSION ]; then /opt/pgsql/bin/initdb --no-locale --encoding=utf8 -U postgres -D /pgsql -X /wal; fi && exec /opt/pgsql/bin/postgres -D /pgsql"]