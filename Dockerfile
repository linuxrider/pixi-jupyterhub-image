FROM ghcr.io/prefix-dev/pixi:0.68.0

WORKDIR /workspace

# Copy pixi project
COPY pixi.toml pixi.lock

# Install environment via pixi
RUN pixi install
