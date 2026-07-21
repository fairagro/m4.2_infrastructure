# Software dependencies (git submodules)

These checkouts provide Docker build contexts for the local kind cluster.
Production still consumes published OCI images/charts from Docker Hub.

| Path | Upstream |
| ---- | -------- |
| `m4.2_advanced_middleware_api` | [github.com/fairagro/m4.2_advanced_middleware_api](https://github.com/fairagro/m4.2_advanced_middleware_api) |
| `m4.2_middleware_harvester` | [github.com/fairagro/m4.2_middleware_harvester](https://github.com/fairagro/m4.2_middleware_harvester) |
| `m4.2_sql_to_arc` | [github.com/fairagro/m4.2_sql_to_arc](https://github.com/fairagro/m4.2_sql_to_arc) |

## Initialise / update

```bash
./scripts/init-submodules.sh
# or
git submodule update --init --recursive --depth 1
```

`m4.2_sql_to_arc` uses Git LFS; `init-submodules.sh` sets `GIT_LFS_SKIP_SMUDGE=1`
(LFS blobs are not required for Docker image builds that copy sources).

## Pin a branch or tag

Git submodules always record a **commit SHA**, not a floating branch name.
To build against a different branch or tag of one of the repos under `deps/`:

### Local only (no infra commit)

```bash
cd deps/m4.2_advanced_middleware_api   # or harvester / sql_to_arc
git fetch --tags origin
git checkout my-feature                # or: git checkout v1.2.3
cd ../..
./scripts/local-dev-build.sh
```

### Pin in this repository (share with others)

```bash
cd deps/m4.2_advanced_middleware_api
git fetch --tags origin
git checkout my-feature                # or tag
cd ../..
git add deps/m4.2_advanced_middleware_api
git status                             # shows: modified: ... (new commits)
git commit -m "Pin advanced middleware API to my-feature"
```

After that, `git submodule update --init` checks out exactly that SHA for everyone.

### Shallow clones

Submodules are configured with `shallow = true` in `.gitmodules`. If `checkout`
cannot find the ref, deepen the history first:

```bash
# branch tip
git -C deps/m4.2_advanced_middleware_api fetch --depth 50 origin my-feature
git -C deps/m4.2_advanced_middleware_api checkout my-feature

# tag
git -C deps/m4.2_advanced_middleware_api fetch --tags --depth 1 origin tag v1.2.3
git -C deps/m4.2_advanced_middleware_api checkout v1.2.3
```
