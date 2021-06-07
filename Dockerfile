FROM buildpack-deps:bionic
# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
# Set up locales properly
RUN apt-get -qq update && \
    apt-get -qq install --yes --no-install-recommends locales > /dev/null && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
# Use bash as default shell, rather than sh
ENV SHELL /bin/bash
# Set up user
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}
RUN groupadd \
        --gid ${NB_UID} \
        ${NB_USER} && \
    useradd \
        --comment "Default user" \
        --create-home \
        --gid ${NB_UID} \
        --no-log-init \
        --shell /bin/bash \
        --uid ${NB_UID} \
        ${NB_USER}
RUN wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key |  apt-key add - && \
    DISTRO="bionic" && \
    echo "deb https://deb.nodesource.com/node_14.x $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list && \
    echo "deb-src https://deb.nodesource.com/node_14.x $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list
# Base package installs are not super interesting to users, so hide their outputs
# If install fails for some reason, errors will still be printed
RUN apt-get -qq update && \
    apt-get -qq install --yes --no-install-recommends \
    less nodejs unzip
    > /dev/null && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8888
# Special case PATH
ENV PATH {{ ':'.join(path) }}:${PATH}
# Allow target path repo is cloned to be configurable
ARG REPO_DIR=${HOME}
ENV REPO_DIR ${REPO_DIR}
WORKDIR ${REPO_DIR}
RUN chown ${NB_USER}:${NB_USER} ${REPO_DIR}
# We want to allow two things:
#   1. If there's a .local/bin directory in the repo, things there
#      should automatically be in path
#   2. postBuild and users should be able to install things into ~/.local/bin
#      and have them be automatically in path
#
# The XDG standard suggests ~/.local/bin as the path for local user-specific
# installs. See https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
ENV PATH ${HOME}/.local/bin:${REPO_DIR}/.local/bin:${PATH}

# Run pre-assemble scripts! These are instructions that depend on the content
# of the repository but don't access any files in the repository. By executing
# them before copying the repository itself we can cache these steps. For
# example installing APT packages.


# Add start script
# Add entrypoint
ENV PYTHONUNBUFFERED=1
COPY /python3-login /usr/local/bin/python3-login
COPY /repo2docker-entrypoint /usr/local/bin/repo2docker-entrypoint
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]
# Specify the default command to run
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
