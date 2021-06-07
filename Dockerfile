FROM buildpack-deps:bionic

ENV HTTP_PROXY="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV HTTPS_PROXY="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV http_proxy="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV https_proxy="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV no_proxy="10.100.0.0/16,172.20.0.0/16,localhost,127.0.0.1, .internal, .local, .ec1.aws.aztec.cloud.allianz, 169.254.169.254,logs.eu-central-1.amazonaws.com,ec2.eu-central-1.amazonaws.com,ecr.eu-central-1.amazonaws.com,sts.eu-central-1.amazonaws.com,elasticloadbalancing.eu-central-1.amazonaws.com,autoscaling.eu-central-1.amazonaws.com, s3.eu-central-1.amazonaws.com, .gitlab.gda.allianz, .gda.allianz,"
ENV NO_PROXY="10.100.0.0/16,172.20.0.0/16,localhost,127.0.0.1, .internal, .local, .ec1.aws.aztec.cloud.allianz, 169.254.169.254,logs.eu-central-1.amazonaws.com,ec2.eu-central-1.amazonaws.com,ecr.eu-central-1.amazonaws.com,sts.eu-central-1.amazonaws.com,elasticloadbalancing.eu-central-1.amazonaws.com,autoscaling.eu-central-1.amazonaws.com, s3.eu-central-1.amazonaws.com, .gitlab.gda.allianz, .gda.allianz,"

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

#RUN wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key |  apt-key add - && \
#    DISTRO="bionic" && \
#    echo "deb https://deb.nodesource.com/node_14.x $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list && \
#    echo "deb-src https://deb.nodesource.com/node_14.x $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list

# Base package installs are not super interesting to users, so hide their outputs
# If install fails for some reason, errors will still be printed
RUN apt-get -qq update && \
    apt-get -qq install --yes --no-install-recommends \
       less \
       nodejs \
       unzip \
       > /dev/null && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8888

# Environment variables required for build
ENV APP_BASE /srv
ENV NPM_DIR ${APP_BASE}/npm
ENV NPM_CONFIG_GLOBALCONFIG ${NPM_DIR}/npmrc
ENV CONDA_DIR ${APP_BASE}/conda
ENV NB_PYTHON_PREFIX ${CONDA_DIR}/envs/notebook
ENV KERNEL_PYTHON_PREFIX ${NB_PYTHON_PREFIX}
# Special case PATH
ENV PATH ${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${NPM_DIR}/bin:${PATH}
# If scripts required during build are present, copy them

#COPY --chown=1000:1000 build_script_files/-2fusr-2flocal-2flib-2fpython3-2e9-2fsite-2dpackages-2frepo2docker-2fbuildpacks-2fconda-2factivate-2dconda-2esh-71eae2 /etc/profile.d/activate-conda.sh

#COPY --chown=1000:1000 build_script_files/-2fusr-2flocal-2flib-2fpython3-2e9-2fsite-2dpackages-2frepo2docker-2fbuildpacks-2fconda-2fenvironment-2efrozen-2eyml-d1d5a1 /tmp/environment.yml

#COPY --chown=1000:1000 build_script_files/-2fusr-2flocal-2flib-2fpython3-2e9-2fsite-2dpackages-2frepo2docker-2fbuildpacks-2fconda-2finstall-2dminiforge-2ebash-0fa46c /tmp/install-miniforge.bash
RUN mkdir -p ${NPM_DIR} && \
chown -R ${NB_USER}:${NB_USER} ${NPM_DIR}

USER ${NB_USER}
#RUN npm config --global set prefix ${NPM_DIR}

USER root
#RUN TIMEFORMAT='time: %3R' \
#bash -c 'time /tmp/install-miniforge.bash' && \
#rm /tmp/install-miniforge.bash /tmp/environment.yml



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

# The rest of the environment
ENV CONDA_DEFAULT_ENV ${KERNEL_PYTHON_PREFIX}
# Run pre-assemble scripts! These are instructions that depend on the content
# of the repository but don't access any files in the repository. By executing
# them before copying the repository itself we can cache these steps. For
# example installing APT packages.
# If scripts required during build are present, copy them

#COPY --chown=1000:1000 src/environment.yml ${REPO_DIR}/environment.yml
USER ${NB_USER}
RUN TIMEFORMAT='time: %3R' \
bash -c 'time mamba env update -p ${NB_PYTHON_PREFIX} -f "environment.yml" && \
time mamba clean --all -f -y && \
mamba list -p ${NB_PYTHON_PREFIX} \
'



# Copy stuff.
COPY --chown=1000:1000 src/ ${REPO_DIR}

# Run assemble scripts! These will actually turn the specification
# in the repository into an image.


# Container image Labels!
# Put these at the end, since we don't want to rebuild everything
# when these change! Did I mention I hate Dockerfile cache semantics?

LABEL repo2docker.ref="None"
LABEL repo2docker.repo="https://github.com/binder-examples/conda"
LABEL repo2docker.version="2021.03.0"

# We always want containers to run as non-root
USER ${NB_USER}

# Add start script
# Add entrypoint
COPY /repo2docker-entrypoint /usr/local/bin/repo2docker-entrypoint
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]

# Specify the default command to run
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
