# Dockerfile: build PostgreSQL from source on Ubuntu with PL/Python
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install build deps (minimal + PL/Python deps)
RUN apt update \
 && apt install -y --no-install-recommends \
    build-essential git wget ca-certificates curl pkg-config \
    flex bison autoconf automake libtool gettext \
    libreadline-dev zlib1g-dev libssl-dev \
    libxml2-dev libxml2-utils libxslt1-dev libbz2-dev liblzma-dev libncursesw5-dev \
    libicu-dev sgml-base docbook-xml docbook-xsl xsltproc sgml-data\
    python3 python3-dev python3-venv python3-distutils python3-pip libpython3-dev postgresql-contrib \
    # extras that might be useful in tests
    locales \
 && rm -rf /var/lib/apt/lists/*

# Create postgres user and data dir for convenience (not strictly required for a build image)
RUN useradd -m postgres || true \
 && mkdir -p /opt/pgsql/ \
 && mkdir -p /pgsql/ \
 && mkdir -p /wal \
 && chown -R postgres:postgres /pgsql /wal

# Set locale (optional but helpful)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Build directory
WORKDIR /usr/local/src

# Clone PostgreSQL source (shallow) and checkout branch/tag
RUN git clone https://git.postgresql.org/git/postgresql.git

WORKDIR /usr/local/src/postgresql

# Ensure python3 (system) is used; PL/Python requires libpython to be shared.
# If you want a custom python, you can install/build it and set PYTHON env before configure.
ENV PYTHON=python3

# Configure, build and install
# --enable-cassert / --enable-debug optional for developer builds (slower but useful)
RUN mkdir /usr/local/src/postgresql/build_dir \
    && cd build_dir \
    && /usr/local/src/postgresql/configure \
          --prefix=/opt/pgsql \
          --with-openssl \
          --with-libxml \
          --with-libxslt \
          --with-python \
    && make world \
    && make install-world

# Expose pg port for runtime usage (optional)
EXPOSE 5432

# Define volumes for data persistence
VOLUME ["/pgsql", "/wal"]

# Initialize PostgreSQL data directory and set up environment
RUN su - postgres -c "echo -e '# Postgresql path\nexport PATH=/opt/pgsql/bin:\$PATH' >> ~/.profile" \
  && su - postgres -c ". ~/.profile" \
  && su - postgres -c "/opt/pgsql/bin/initdb --no-locale --encoding=utf8 -U postgres -D /pgsql -X /wal"

# Create a startup script
RUN echo '#!/bin/bash' > /start-postgres.sh \
 && echo 'echo "Starting PostgreSQL..."' >> /start-postgres.sh \
 && echo 'su - postgres -c "PGDATA=/pgsql/ /opt/pgsql/bin/pg_ctl -D /pgsql -l /tmp/postgres.log start"' >> /start-postgres.sh \
 && echo 'echo "PostgreSQL started. To create PL/Python extension run:"' >> /start-postgres.sh \
 && echo 'echo "  CREATE EXTENSION plpython3u;"' >> /start-postgres.sh \
 && echo 'echo "Log location: /tmp/postgres.log"' >> /start-postgres.sh \
 && echo 'exec bash' >> /start-postgres.sh \
 && chmod +x /start-postgres.sh

# Set the default command
CMD ["/start-postgres.sh"]
