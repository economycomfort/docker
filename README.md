# docker

Various services for homelab operation.

## Description

Provides a single `docker-compose.yaml` file which defines granular docker
services, networks, and volumes. This file makes use of [Compose profiles](https://docs.docker.com/compose/profiles/), 
each profile representing a docker host which runs a set of services.

Most defined services have a single profile representing the host they are
intended to run on. However, some services may contain no profile definition,
indicating they are a common service. Other services may contain multiple
profile definitions, indicating they are only to be run with specific profiles.
  
Most, but not all, services are intended to have their web interfaces,
if applicable, exposed through a Traefik reverse proxy container running on the
same docker host.  

### Environment (`.env`)

An `.env` file must be present in order to define some variables which will be
referenced within `docker-compose.yaml`.  For convenience, a file named
`.env.example` is present within the repo, and can be used as a template, or 
simply filled out and renamed to `.env`.

While most values should be rather self-explanatory, the following information
is provided for posterity:
  
- `DOMAINNAME`: Set to the domain name that the reverse proxy (Traefik)
  container will use to expose services.  

	Traefik uses this domain name to generate dynamic, valid LetsEncrypt 
  certificates via ACME.  This Traefik instance is using a Cloudflare backend 
  (see the `secrets` definition within `docker-compose.yaml`), however specific 
  container configuration is not covered here.

  Services exposed through Traefik should be then accessible via
  `https://${service_name}.${DOMAINNAME}`.  For example, `https://emby.app.vhf.sh`.

  DNS records should be present to point the container hostnames to the IP of
  the docker host itself.

- `TZ`: Specifies a timezone for a container.  Applies only to 
  `linuxserver`-maintained docker images.

- `PUID`: Set to the UID of the user the container should run as.  Applies only 
  to `linuxserver`-maintained docker images.

- `PGID`: Set to the GID of the group the container should run as (probably the 
  `docker` group).  Applies only to `linuxserver`-maintained docker images.

- `APPDATA`: By default, points to `./appdata`, which should be a symlink to the
  location where service configuration files reside.

  - The `./appdata` symlink will need to be created manually.
  
  - Generally, servo stores configuration for its
    services in `/mnt/fast/appdata/servo`.

  - For homebot services, they are probably in `~/appdata` on homebot, with
    configuration backups held on servo in `/mnt/fast/appdata/homebot`, in the
    event they need to be restored.  This is to accomodate homebot being able
    to run home automation services without the need for servo being available,
    for instance during a Proxmox failover migration.

-	`COMPOSE_PROFILES`: Set to reflect the default profile to be used by the 
  Docker host in question.

-	`COMPOSE_PROJECT_NAME`: Set to whatever the Docker project should be called.  
  Docker prepends this value onto volume names, network names, etc. in order for 
  them to be easily identified.  It's probably fine to set this to the same 
  value defined in `COMPOSE_PROFILES`.

## Secrets
Files within the `secrets` directory are GPG encrypted upon commit with 
`git-crypt`.  After cloning, use `git-crypt unlock` and enter the GPG key 
passphrase to decrypt.  Of course, you will need the GPG key, not provided in
this repo.

To decrypt, make sure you've added a GPG key with 
`git-crypt add-gpg-user <GPG_KEY_ID>`.

**More info:**
  - https://www.guyrking.com/2018/09/22/encrypt-files-with-git-crypt.html
  - https://dev.to/heroku/how-to-manage-your-secrets-with-git-crypt-56ih

See `.gitattributes` for filenames/globs in this repository which are encrypted.  
If it's not listed there, it's fine.

## Starting Services
If `.env` is properly defined, starting services should be the same as any other
docker host, as the profile will be read and automatically applied.  Services
without a specified profile will come up and down as well.

Start all services:
`docker compose up -d`

Start only `homebot`-profiled services:
`docker compose --profile homebot up -d`

Start only `servo`-profiled services:
`docker compose --profile servo up -d`

**More info**:
  - https://docs.docker.com/compose/profiles/
  - https://nickjanetakis.com/blog/docker-tip-94-docker-compose-v2-and-profiles-are-the-best-thing-ever
