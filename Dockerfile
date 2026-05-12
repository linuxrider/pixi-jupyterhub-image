FROM ghcr.io/prefix-dev/pixi:0.68.0

WORKDIR /workspace

# Copy pixi project
COPY pixi.toml pixi.lock ./

# Install environment via pixi
RUN pixi install

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
