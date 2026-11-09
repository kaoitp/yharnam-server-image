# Yharnam Together server image for Unraid

[ไทย](README.md) | [English](README.en.md)

This repository builds a `linux/amd64` image from published [Yharnam Together releases](https://github.com/Amanises-Yharnam-Together/BBSC-Yharnam-Together/releases), including prereleases, using the release's Dockerfile and pinned protobuf submodule. The image does not contain the game or client. Match the image tag to every player's client release. The template defaults to `yharnam-server-tailscale:latest`; `latest` can change and may not match your client, so check Actions and the package before installing.

## Builds and versions

Actions checks daily at 03:23 UTC and selects the most recently published release by `published_at`, including prereleases and excluding drafts. It checks out that tag, fetches its pinned protobuf, builds the image and checks that the server responds to the admin command and creates `link_key.bin` before pushing `ghcr.io/kaoitp/yharnam-server:<tag>`. It also points `latest` to the newest published release, including a prerelease. Manually building an older release does not move `latest`. No workflow updates Unraid.

If several releases appear between checks, only the most recently published is selected. To build another published release, open Actions → Build upstream server → Run workflow, enter the release tag, and wait for success. Existing version tags are skipped rather than rebuilt. `latest` is mutable, so use a version tag or digest matching the client to control updates, especially when pulling or recreating the container.

Registry errors other than a missing tag stop the workflow; check its log on failure. A pre-existing package not linked to this repository may require Actions access in its package settings. GHCR does not prevent another workflow from changing a tag concurrently. Use a digest for an exact image. Upstream can move a release tag; an already published version image is not automatically rebuilt.

The separate `ghcr.io/kaoitp/yharnam-server-tailscale:<tag>-ts2` image (for example, client `v1.4.0` uses `v1.4.0-ts2`) is built from the matching version image. Its hook starts as root and gosu drops the server to UID 10001; the Tailscale daemon retains the privileges needed to manage networking. Tailscale 1.104.5 is bundled with a build-time checksum check to avoid downloading it at container startup; it does not update itself and needs a new image for updates. Check the `tailscale-image` job before use.

## GHCR access

After the first push, go to GitHub → `kaoitp` profile → Packages → `yharnam-server-tailscale` → Package settings → Change visibility → Public to permit anonymous pulls. A public image is readable by everyone. Alternatively, keep it Private and log in on Unraid with an account that can read the package and a classic PAT with `read:packages`, using `docker login ghcr.io` and entering the token interactively. Never put the token in Compose or chat. See [GitHub's package access guide](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility). If a push fails, check repository Settings → Actions → General → Workflow permissions and package settings → Manage Actions access for write access. GitHub may restrict changing visibility back after publication.

## Install on Unraid using the Docker template

This template is not listed in the public Community Apps search yet; import it manually. Compose is not required. Use x86-64 Unraid with Docker enabled:

1. Open the Unraid terminal and download the template. This command does not overwrite an existing file with the same name:

   ```sh
   test ! -e /boot/config/plugins/dockerMan/templates-user/my-Yharnam-Together-Tailscale.xml && \
     curl -fL https://raw.githubusercontent.com/kaoitp/yharnam-server-image/main/templates/yharnam-together-server.xml \
     -o /boot/config/plugins/dockerMan/templates-user/my-Yharnam-Together-Tailscale.xml
   ```

   If the file exists, inspect it before replacing it. If you imported the older host-network template, import this new filename and select the Tailscale template; existing containers are not changed automatically. If your UI has a Template repositories field, you can add `https://github.com/kaoitp/yharnam-server-image` instead and select the template from the list.
2. Create a **new** data directory in the Unraid terminal and grant access to the image user only for this directory. Do not use these commands on a directory containing unrelated data:

   ```sh
   if [ -e /mnt/user/appdata/yharnam-server ]; then
     echo 'Directory exists; inspect and back up before changing permissions.'
   else
     mkdir -p /mnt/user/appdata/yharnam-server && \
       chown 10001:10001 /mnt/user/appdata/yharnam-server && \
       chmod 750 /mnt/user/appdata/yharnam-server
   fi
   ```

   If data already exists, inspect permissions and back it up first; do not run `chown -R` without checking. `/data` holds worlds, databases, settings and `link_key.bin`; use reliable local storage.
3. Go to Docker → Add Container → Template and select `Yharnam-Together-Tailscale` (possibly under User templates). Set **Repository** to `ghcr.io/kaoitp/yharnam-server-tailscale:<tag>-ts2` for a successfully built release matching all clients; the default is `latest`. Check **Server data** points to your prepared directory, then click Apply. Check the container logs and confirm Tailscale actually connects; the hook may start the server without Tailscale if it fails.
4. On Unraid 7 or newer, enable **Use Tailscale**, choose a unique hostname, and use kernel networking (disable Tailscale Userspace Networking). Apply and follow the authentication link in the logs to join your Tailnet. Players need Tailscale and should use the **container** Tailscale IP in the client. The bridge template publishes no host ports; Serve and Funnel are not needed. See [Unraid Tailscale documentation](https://docs.unraid.net/unraid-os/system-administration/secure-your-server/tailscale/).

The template uses the `unless-stopped` restart policy, which does not pull new images. Exclude this container from automatic updates. Avoid `latest` if you need the release pinned to your clients when pulling or recreating the container.

## Backup, update and rollback

Do this after everyone has left the game:

1. Stop `Yharnam-Together-Tailscale` on the Docker page and wait for a clean stop, so SQLite and world journals are consistent.
2. Copy the **entire data directory** `/mnt/user/appdata/yharnam-server`, including hidden files, permissions and `link_key.bin`, to a backup separate from Unraid. Save the Repository tag or digest and template settings too. Protect the backup because it contains account data, the server key, and Tailscale state. Verify it and test restoration on a separate machine.
3. Confirm the new release's Actions run succeeded and all clients match it. On the Docker page choose Edit for the container, change the Repository tag and click Apply to pull and recreate the container using the same data path. Check logs before players join.
4. To roll back, stop the container, save a separate copy of current data, restore the entire pre-update backup, then Edit the Repository back to the old tag and Apply. Restoring loses progress made after the backup; data written by a newer server may not work with the older one. Do not replace `link_key.bin` with a new key: clients may no longer trust the server.

If the logs show `Can't get Tailscale JSON`, check that you pulled a new `-ts2` image or the current `latest`. The bundled image should cause the hook to say `Tailscale found, continuing`. Then check the logs for Tailnet authentication; never share auth keys or Tailscale state.

The workflow tests the real hook and daemon in userspace without joining a Tailnet and simulates the handoff to the server. It does not verify kernel networking, joining a Tailnet, UDP multiplayer, or actual Unraid operation.
