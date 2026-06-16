# Cursor devcontainer (DevPod)

Used by `scripts/start-devcontainer-cursor.sh` with DevPod + Cursor.

## Host bind mounts

| Mount | Source | Platforms |
| ----- | ------ | --------- |
| Git config | `${localEnv:HOME}${localEnv:USERPROFILE}/.gitconfig` (read-only) | Linux, macOS, Windows |
| GPG agent socket | `${localEnv:XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.extra` | **Linux only** |
| GPG trustdb | `${localEnv:HOME}/.gnupg/trustdb.gpg` | Linux, macOS, Windows (optional file) |

## GPG agent forwarding (Linux only)

The GPG agent bind mount relies on `XDG_RUNTIME_DIR`, which systemd sets on Linux
(typically `/run/user/<uid>`). It is usually **not** set on macOS or Windows.

If `XDG_RUNTIME_DIR` is empty, the mount source resolves to `/gnupg/S.gpg-agent.extra`,
which does not exist, and **devcontainer creation fails**.

### Linux

Before `devpod up --recreate`, ensure the host agent is running:

```bash
gpg -K
```

Host `~/.gitconfig` is mounted read-only.

`scripts/setup-container-gpg.sh` (postCreate) symlinks the host agent socket to
`~/.gnupg/S.gpg-agent`, copies the host `trustdb.gpg` into a **writable** local file
(readonly bind mounts cannot be symlink targets for imports), and imports
`environments/*/public_gpg_keys/*.asc`.

## One-time setup (postCreateCommand)

These run once per devcontainer create (not on every shell):

- `scripts/setup-container-gpg.sh` (host agent + trustdb + public keys)
- `scripts/setup-container-docker.sh` (DevPod DinD Docker config workaround)

`scripts/load-env.sh` is sourced from `~/.bashrc` and sets up aliases and completions.
`scripts/set_context.sh fizz` is also sourced from `~/.bashrc` to connect to the fizz
cluster (requires GPG passphrase for SOPS decryption).

For a **local clone outside devcontainers**, import public keys once:

```bash
./scripts/import-public-gpg-keys.sh
```

### macOS / Windows

This devcontainer variant does not support host GPG agent forwarding. Options:

1. **Decrypt kubeconfig on the host** before starting the container and mount it manually.
2. **Remove the GPG-related `mounts` entries** from `devcontainer.json` and import keys
   manually inside the container via `scripts/import-public-gpg-keys.sh`.

DevPod's `--gpg-agent-forwarding` flag is not used here; it is a separate code path and
was found unreliable on some Linux hosts.

## Quick start

```bash
./scripts/start-devcontainer-cursor.sh
./scripts/start-devcontainer-cursor.sh --recreate
```
