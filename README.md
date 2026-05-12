# Pixi + JupyterHub Spawner Image

A minimal Docker image for JupyterHub single-user servers with Pixi package management.

This image is designed to be spawned by JupyterHub's `DockerSpawner` or Kubernetes spawner. It provides users with JupyterLab, Pixi, and a minimal Python environment.

## What's Included

- **Python 3.14** via Pixi
- **JupyterLab** for the notebook interface
- **Pixi** package manager for installing additional packages
- **NumPy, Pandas, Polars** as example data libraries (customize in `pixi.toml`)

## Usage

### Build

```bash
docker build -t pixi-jupyterhub:latest .
```

Or push to a registry:

```bash
docker build -t ghcr.io/your-org/pixi-jupyterhub:latest .
docker push ghcr.io/your-org/pixi-jupyterhub:latest
```

### Local Testing

```bash
docker run -p 8888:8888 pixi-jupyterhub:latest
```

Then open `http://localhost:8888` in your browser.

## JupyterHub Deployment

Configure your JupyterHub `jupyterhub_config.py`:

```python
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"
c.DockerSpawner.image = "ghcr.io/your-org/pixi-jupyterhub:latest"
c.DockerSpawner.network_name = "jupyterhub"
```

For Kubernetes:

```python
c.JupyterHub.spawner_class = "kubespawner.KubeSpawner"
c.KubeSpawner.image = "ghcr.io/your-org/pixi-jupyterhub:latest"
```

## Customizing the Environment

Edit `pixi.toml` to add or remove packages:

```toml
[dependencies]
python = "3.14.*"
jupyterlab = "*"
jupyterhub-singleuser = "*"
numpy = "*"
your-package = "*"
```

Then regenerate the lock file and rebuild:

```bash
pixi lock
docker build -t pixi-jupyterhub:latest .
```

## Architecture

- **Base image**: `ghcr.io/prefix-dev/pixi:0.68.0` — includes Pixi
- **Build time**: Single `pixi install` from locked dependencies
- **Runtime**: JupyterHub spawns `jupyterhub-singleuser` inside the container

The image is kept minimal — users can install additional packages via `pixi add` within JupyterLab if needed.

## Development

To update dependencies:

```bash
pixi add new-package
pixi lock
```

To test locally before pushing:

```bash
docker build -t pixi-jupyterhub:test .
docker run -p 8888:8888 pixi-jupyterhub:test
```

## GitHub Actions

This repository includes a GitHub Actions workflow that:
- Lints the Dockerfile
- Builds and pushes to GHCR on `main` branch and `v*` tags
- Caches build layers for faster rebuilds
- Auto-generates semantic version tags
