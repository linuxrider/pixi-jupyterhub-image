FROM ghcr.io/prefix-dev/pixi:latest

WORKDIR /workspace

# Copy pixi project
COPY pixi.toml pixi.lock .

# Install environment via pixi
RUN pixi install
