# Docker container for machine learning development

## Get started

```shell
git clone https://github.com/tatsy/docker-mlenv
cd docker-mlenv
docker compose build  # Build the Docker image
docker compose up -d  # Run the container as a daemon
docker exec -it mlenv-app /usr/bin/zsh
