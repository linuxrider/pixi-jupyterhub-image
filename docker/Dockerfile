FROM ghcr.io/prefix-dev/pixi:0.69.0

ARG NB_USER="jovyan"
ARG NB_UID="1000"

ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    HOME=/home/${NB_USER} \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    rm -rf /var/lib/apt/lists/* && \
    usermod -l ${NB_USER} ubuntu && \
    groupmod -n ${NB_USER} ubuntu && \
    usermod -d /home/${NB_USER} -m ${NB_USER} && \
    chown -R ${NB_UID}:${NB_UID} /home/${NB_USER}

WORKDIR /workspace

COPY pixi.toml pixi.lock ./
RUN pixi install --locked && \
    chown -R ${NB_UID}:${NB_UID} /workspace

COPY docker/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV JUPYTER_PORT=8888
EXPOSE ${JUPYTER_PORT}

USER ${NB_USER}

CMD ["jupyterhub-singleuser"]
ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/entrypoint.sh"]
