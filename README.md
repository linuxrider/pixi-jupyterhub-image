# Pixi + JupyterHub Spawner Image

A minimal Docker image for JupyterHub single-user servers using Pixi for package management.

Designed to be spawned by JupyterHub's `DockerSpawner` or Kubernetes spawner.

## What's Included

- **Python 3.14** via Pixi (conda-forge)
- **JupyterLab** notebook interface
- **jupyterhub-singleuser** server extension
- **ipykernel** Python kernel for notebooks
- **tini** init process (PID 1, signal handling, zombie reaping)
- Non-root user `jovyan` (UID 1000), matching official Jupyter Docker Stacks convention

## Architecture

```
ghcr.io/prefix-dev/pixi:0.69.0  (Ubuntu base + pixi binary)
         ↓
  rename ubuntu → jovyan (UID 1000)
  pixi install --locked → /workspace/.pixi/envs/default/
  copy tini to /usr/local/bin/
         ↓
ENTRYPOINT: tini -g -- entrypoint.sh
CMD:        jupyterhub-singleuser
```

At startup, `entrypoint.sh` runs `pixi shell-hook` to activate the environment (prepends `/workspace/.pixi/envs/default/bin` to `PATH`), then execs the command.

## Prerequisites

- [Pixi](https://pixi.sh) installed
- Docker installed and the current user in the `docker` group (all tasks invoke Docker)

## Local Development

```bash
# Build image
pixi run build

# Verify image: user, Python, JupyterLab, jupyterhub-singleuser, tini (non-interactive)
pixi run check

# Run standalone JupyterLab (no hub required, open http://localhost:8888)
pixi run run-lab

# Drop into a shell as root (for debugging)
pixi run shell

# Drop into a shell as jovyan (runtime user)
pixi run shell-user

# Simulate JupyterHub spawn env vars (hub connection will fail without a real hub)
pixi run test

# Full integration test: spin up JupyterHub, spawn the image, verify end-to-end
pixi run hub-test

# Interactive: spin up JupyterHub at http://localhost:8000 (login: any user, password: localtest)
pixi run hub-serve
```

## JupyterHub Deployment

Configure `jupyterhub_config.py` for DockerSpawner:

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
tini = "*"
your-package = "*"
```

Regenerate the lock file and rebuild:

```bash
pixi install
pixi run build
```

## Custom User / UID

The image exposes `NB_USER` (default: `jovyan`) and `NB_UID` (default: `1000`) as build args.
The base image already has `ubuntu` at UID 1000, which is renamed at build time.
To use a different name, rebuild with:

```bash
docker build --build-arg NB_USER=myuser -t pixi-jupyterhub .
```

Note: changing `NB_UID` requires a base image where that UID is free.

## GitHub Actions

Images are built and pushed to GHCR on every branch push and version tag:

| Trigger | Tags produced |
|---|---|
| push to `main` | `latest`, `main`, `main-<sha>` |
| push to any branch | `<branch>`, `<branch>-<sha>` |
| `v1.2.3` tag | `1.2.3`, `1.2` |

Configure the registry in the workflow if pushing to your own org.
