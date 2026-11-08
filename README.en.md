# Yharnam Together server image for Unraid

[ไทย](README.md) | [English](README.en.md)

This repository builds a `linux/amd64` image from published [Yharnam Together releases](https://github.com/Amanises-Yharnam-Together/BBSC-Yharnam-Together/releases), including prereleases, using the release's Dockerfile and pinned protobuf submodule. The image does not contain the game or client. Match the image tag to every player's client release. `v1.4.0` in the Compose file is an example; check Actions and the package before installing.

## Builds and versions

Actions checks daily at 03:23 UTC and selects the most recently published release by `published_at`, including prereleases and excluding drafts. It checks out that tag, fetches its pinned protobuf, builds the image and checks that the server responds to the admin command and creates `link_key.bin` before pushing `ghcr.io/kaoitp/yharnam-server:<tag>`. It also points `latest` to the newest published release, including a prerelease. Manually building an older release does not move `latest`. No workflow updates Unraid.

If several releases appear between checks, only the most recently published is selected. To build another published release, open Actions → Build upstream server → Run workflow, enter the release tag, and wait for success. Existing version tags are skipped rather than rebuilt. `latest` is mutable, so use a version tag or digest matching the client to control updates, especially when pulling or recreating the container.

Registry errors other than a missing tag stop the workflow; check its log on failure. A pre-existing package not linked to this repository may require Actions access in its package settings. GHCR does not prevent another workflow from changing a tag concurrently. Use a digest for an exact image. Upstream can move a release tag; an already published version image is not automatically rebuilt.

## GHCR access

After the first push, go to GitHub → `kaoitp` profile → Packages → `yharnam-server` → Package settings → Change visibility → Public to permit anonymous pulls. A public image is readable by everyone. Alternatively, keep it Private and log in on Unraid with an account that can read the package and a classic PAT with `read:packages`, using `docker login ghcr.io` and entering the token interactively. Never put the token in Compose or chat. See [GitHub's package access guide](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility). If a push fails, check repository Settings → Actions → General → Workflow permissions and package settings → Manage Actions access for write access. GitHub may restrict changing visibility back after publication.

## Install on Unraid

1. Use x86-64 Unraid with Docker and Compose. Confirm the selected image tag was built successfully and matches all clients. Copy `compose.yaml` to a project directory, for example `/boot/config/yharnam-server`, and edit `image:` to select that tag.
2. In the Unraid terminal, create a **new** data directory and grant access to image user 10001:10001. Do not change ownership of a directory containing unrelated data:

   ```sh
   mkdir -p /mnt/user/appdata/yharnam-server
   chown 10001:10001 /mnt/user/appdata/yharnam-server
   chmod 750 /mnt/user/appdata/yharnam-server
   ```

   If the directory already has data, inspect permissions and back it up first. Do not run `chown -R` without checking. `/data` holds databases, worlds, settings, and `link_key.bin`; use reliable local storage.
3. From the Compose directory, run `docker compose pull`, then `docker compose up -d`. Check `docker compose logs -f shadnet` and `docker compose ps`; Ctrl+C stops following logs.
4. Host networking is used. Check for conflicts on UDP 31314 and TCP 31315 and 20443. Limit firewall/VPN access to trusted players as needed. Do not expose TCP 31313 or stats port 31320 publicly. Ports 31315 and 20443 use unencrypted HTTP. See the [upstream hosting guide](https://github.com/Amanises-Yharnam-Together/BBSC-Yharnam-Together/blob/v1.4.0/server/hosting/README.md), then set the Unraid host IP in the client.

`restart: unless-stopped` restarts the existing container after a reboot; it does not pull a new image. Exclude this container from automatic update tools.

## Backup, update and rollback

Do this after everyone has left the game:

1. From the Compose directory run `docker compose stop` and wait for a clean stop so SQLite and world journals are consistent.
2. Copy the **entire** `/mnt/user/appdata/yharnam-server` directory, including hidden files, permissions and `link_key.bin`, to a backup separate from Unraid. Save `compose.yaml` and the old tag/digest too. Protect the backup: it contains account data and the server key. Verify it and test restoration on a separate machine before relying on it.
3. Change the Compose tag to the new client release, verify its Actions run succeeded, then run `docker compose pull` and `docker compose up -d`. Check the logs before players join.
4. To roll back, stop the container again, save a separate copy of the current data, restore the entire pre-update backup and set the Compose tag back to the old version. Run `docker compose up -d`. Restoring a backup loses progress made since it was taken; data written by a newer server may not work with the older one. Do not replace `link_key.bin` with a new key: clients may no longer trust the server.

The workflow tests server startup only; it does not verify actual multiplayer or Unraid operation.
