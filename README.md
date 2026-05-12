# Pixi + JupyterHub Base Image

This repository provides a Docker setup that extends a Pixi-based environment
with JupyterHub and JupyterLab support so it can run properly inside JupyterHub.

## Features

- Pixi environment management
- JupyterLab
- JupyterHub single-user server
- Configurable Docker image
- Ready for Kubernetes / DockerSpawner

## Build

```bash
docker build -t pixi-jupyterhub .
```

## Run locally

```bash
docker run -p 8888:8888 pixi-jupyterhub
```

## Example JupyterHub config

```python
c.Spawner.cmd = ["jupyterhub-singleuser"]
c.DockerSpawner.image = "pixi-jupyterhub:latest"
```