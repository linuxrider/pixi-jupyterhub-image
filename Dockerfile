FROM ghcr.io/prefix-dev/pixi:0.69.0

WORKDIR /workspace

# Copy pixi project
COPY pixi.toml pixi.lock ./

# Install environment via pixi
RUN pixi install

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
