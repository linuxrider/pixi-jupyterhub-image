import os

c.JupyterHub.authenticator_class = "shared-password"
c.SharedPasswordAuthenticator.user_password = "localtest"

c.Authenticator.admin_users = {"admin"}
c.Authenticator.allow_all = True

c.JupyterHub.services = [
    {
        "name": "integration-test",
        "api_token": os.environ["JHUB_TEST_TOKEN"],
        "admin": True,
    }
]

c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"
c.DockerSpawner.image = os.environ.get("JHUB_TEST_IMAGE", "pixi-jupyterhub")
c.DockerSpawner.pull_policy = "never"
c.DockerSpawner.network_name = os.environ["JHUB_TEST_NETWORK"]
c.DockerSpawner.remove = True
c.DockerSpawner.extra_labels = {"jhub-network": os.environ["JHUB_TEST_NETWORK"]}

c.JupyterHub.hub_connect_ip = os.environ["JHUB_TEST_GATEWAY"]

c.ConfigurableHTTPProxy.api_url = f"http://127.0.0.1:{os.environ['JHUB_PROXY_API_PORT']}"

work_dir = os.environ["JHUB_WORK_DIR"]
c.JupyterHub.cookie_secret_file = f"{work_dir}/cookie_secret"
