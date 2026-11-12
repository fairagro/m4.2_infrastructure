# Optional local build contexts (not git submodules)

These directories are **not** tracked. Clone them only when you run the kind local stack and want to build images from
source (`./scripts/local-dev-build.sh`). Production and fizz/draven still use published OCI images from Docker Hub.

| Path                           | Upstream                                                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `m4.2_advanced_middleware_api` | [github.com/fairagro/m4.2_advanced_middleware_api](https://github.com/fairagro/m4.2_advanced_middleware_api) |
| `m4.2_middleware_harvester`    | [github.com/fairagro/m4.2_middleware_harvester](https://github.com/fairagro/m4.2_middleware_harvester)       |
| `m4.2_sql_to_arc`              | [github.com/fairagro/m4.2_sql_to_arc](https://github.com/fairagro/m4.2_sql_to_arc)                           |

## Clone (once)

```bash
git clone https://github.com/fairagro/m4.2_advanced_middleware_api.git deps/m4.2_advanced_middleware_api
git clone https://github.com/fairagro/m4.2_middleware_harvester.git deps/m4.2_middleware_harvester
# sql_to_arc uses Git LFS; skip LFS blobs for image builds that only need sources:
GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/fairagro/m4.2_sql_to_arc.git deps/m4.2_sql_to_arc
```

Then checkout any branch/tag you need inside each clone and run `./scripts/local-dev-build.sh`.
