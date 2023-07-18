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

It is important to modify the `.env` file to reflect the environment the
services run in on the host that is intended to run them. Note that variables
within `.env` must all be defined; the default values may not suit your
environment, and blank values must be completed.

While most values should be rather self-explanatory, the following information
is provided for posterity:
  
- `DOMAINNAME`: Set to the domain name which will expose services.  

	Traefik uses this domain name to generate dynamic, valid LetsEncrypt 
  certificates via ACME.  This Traefik instance is using a Cloudflare backend 
  (see the `secrets` definition within `docker-compose.yaml`), however specific 
  container configuration is not covered here.

- `TZ`: Specifies a timezone for a container.  Applies only to 
  `linuxserver`-maintained docker images.

- `PUID`: Set to the UID of the user the container should run as.  Applies only 
  to `linuxserver`-maintained docker images.

- `PGID`: Set to the GID of the group the container should run as (probably the 
  `docker` group).  Applies only to `linuxserver`-maintained docker images.

- `APPDATA`: Set to the filesystem location where container-specific 
  configuration is found.

	For convenience, an `appdata/` directory is provided in the repo.  Subdirectories
  here enumerate application configuration for different profiles; in this case, a
  profile = a docker host. Some complexity is necessary here to satisfy the
  requirement that home automation services should be minimally configured and as
  portable as possible.  This prevents using something like an NFS mount to share
  application configuration, as home automation services should continue to run even
  if the primary storage host is down, or not present (in the event of a Proxmox
  failover, for instance).

	- The `homebot` subdirectory contains configuration for `homebot`-profile 
    services.  Given their minimal-configuration requirement, configuration for 
    these services are included in this repo (and GPG-encrypted with `git-crypt` 
    where prudent).
	
	- The `servo` symlink should point to where applications hosted on `servo` 
    should exist.  In this case, these applications have their configuration on 
    `fast/appdata`, an NVMe-backed ZFS mirror.

	In summary, set `APPDATA` to where the application's configuration should 
  exist on the host the `docker-compose.yaml` file is running from.

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
