# FAIRagro m4.2_infrastructure #

Infrastructure-as-Code to deploy services needed by measure 4.2

## How to deal with this project ##

This project delivers a dev container with all tools needed (kubectl, helm, sops, argocd, etc.).

### VS Code / Cursor ###

Open the repository and choose **Reopen in Container** (or **Clone in Volume**).
The configuration lives at `.devcontainer/devcontainer.json`.

### PR quality gates ###

PRs to `main` run automated Helm/YAML/commit/secret/shell checks (see
[docs/ops/pr-quality-gates.md](docs/ops/pr-quality-gates.md)). In the Dev Container,
`postCreateCommand` runs `npm ci` and installs pre-commit hooks (`pre-commit` +
`commit-msg`, including commitlint). After a rebuild, commits fail early locally
if messages violate Conventional Commits.

Outside the container (or after cloning without rebuild):

```bash
npm ci
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

Use Conventional Commits (`commitlint.config.cjs`). After CI lands, a repo admin
should mark the listed check names **required** on the `main` ruleset (documented
in the same ops page).

### Local stack (kind + DinD) ###

To exercise API + harvester together without pushing to Docker Hub, use the `local_dev`
environment. Software sources live as **git submodules** under `deps/` (initialised by
`postCreateCommand`).

```bash
# Prefer when cloning outside an existing Dev Container:
git clone --recurse-submodules https://github.com/fairagro/m4.2_infrastructure.git

# Inside the Dev Container:
./scripts/init-submodules.sh      # if postCreate already ran, this is a no-op refresh
./scripts/local-dev-up.sh         # kind cluster + ingress-nginx
./scripts/local-dev-build.sh      # docker build from deps/ + kind load
./scripts/local-dev-deploy.sh     # helm install with environments/local_dev/values
source ./scripts/set_context.sh local_dev
```

Details: `environments/local_dev/README.md` and `deps/README.md`.

### GitOps bootstrap (Argo CD) ###

Cluster deploys for **fizz**, **elise**, and **draven** use Path A (App-of-Apps,
**no** Root Application — avoids an extra version layer):

1. Checked-in **wrapper** Application under `environments/<env>/argocd/`
   (`fairagro-m42-applications`): fizz/elise pin `targetRevision: main`;
   draven pins `targetRevision: '*'` (highest SemVer git tag).
2. Bootstrap applies that manifest once (script / `argocd app create -f`). Re-run
   only when the wrapper YAML itself changes (rare). Workload pins live in
   `environments/<env>/values/` (child `*_revision`, image tags).
3. Child Applications come from the umbrella Helm chart; fizz-class children
   use `main`, draven uses `lock_children_to_revision: "*"` so children share
   the same SemVer resolution as the wrapper.
4. CI must **not** rewrite Application YAML pins. Releases for draven are git
   SemVer tags only (Actions workflow **release**, issue #42).

#### Image pins (fizz trial vs draven promote) ####

Image tags live **per environment overlay** (`environments/<env>/values/`), not as one
shared “main version”:

| Environment | Allowed pins | How they reach the cluster |
|-------------|--------------|----------------------------|
| fizz / elise | product **pre-releases** and releases | merge to `main` → Argo tracks `main` |
| draven | product **releases only** (no `-rc` / SemVer pre-release) | promote PR on `main`, then infra SemVer **tag** → Argo `*` |

An infra tag may still contain fizz/elise pre-release pins; that does **not** affect
draven. `./scripts/check_draven_release_pins.sh` (and CI) enforce the draven-only rule.

**Operator sequence** (one product change: api / harvester / sql-to-arc):

1. Product: feature branch → **pre-release**
2. Infra **fizz trial PR**: bump only `environments/fizz/values/...` `image.tag` (elise if needed) → merge → fizz auto-deploys
3. Validate on fizz (for harvester: schedule a one-off Job with
   `./scripts/create_harvester_test_job.sh` — see below; do **not** use plain
   `kubectl create job --from=cronjob/…` under automated prune)
4. Product: merge → **prod release** (version now known)
5. Infra **draven promote PR**: bump `environments/draven/values/...` to that prod release; optionally align fizz off `-rc` in the same or a follow-up PR
6. Infra **release** workflow on `main` (Actions → **release**): choose `version_bump`, set Soft
   **fizz_validated**, validate-then-tag → draven follows `*`. To undo a bad tag without Argo UI,
   run Actions → **release-rollback** (SemVer release rollback #57). Cluster-side **emergency pin**:
   [docs/ops/emergency-pin.md](docs/ops/emergency-pin.md) (#68). Deploy failure notifications: #43.

Do **not** bundle the fizz trial with the draven promote: the prod version is not known
yet at trial time. Merging a draven promote updates `main` but the cluster stays on the
previous tag until the release workflow cuts a new SemVer tag.

#### Infra SemVer tags (draven) ####

Cut tags only via **Actions → release** on `main` (do not push ad-hoc SemVer tags; a Ruleset
may enforce this later). Inputs:

- `version_bump`: `major` | `minor` | `patch` (default `patch`) — same manual model as product repos
- `fizz_validated`: Soft checkbox — you validated relevant changes on fizz (honor-system; no
  image-lineage check in this workflow)

Gates before tag: Soft checkbox must be true; `./scripts/check_draven_release_pins.sh` must pass.
The workflow does **not** rewrite Application YAML or env values.

**Leitplanken** (human choice; CI does not auto-bump from commits):

| Bump | When |
|------|------|
| `patch` | Normal case: image-pin promote, small config/docs in the tagged tree, most releases |
| `minor` | New stack capability (new chart/child, meaningful template change, new RDI enabled on draven) |
| `major` | Breaking for cluster ops (Values schema removal/rename, mandatory infra change) — rare |

First tag when none exist: `patch`/`minor` → `0.1.0`; `major` → `1.0.0`.
Preview locally: `./scripts/compute_next_infra_semver.sh patch` (uses existing git tags).

**Chicken-egg for draven:** Argo `targetRevision: '*'` cannot resolve until at least one
plain SemVer tag exists. Cut the **first** infra release (Actions → **release**) **before**
running bootstrap for draven; otherwise `argocd app create` fails with
`unable to resolve '*' to a commit SHA`. fizz/elise (`main`) have no such dependency.

#### Harvester one-off test Jobs (fizz) ####

Child Apps use automated sync with **prune**. A plain
`kubectl create job --from=cronjob/fairagro-advanced-middleware-harvester` is
tracked but not in Git, so Argo deletes it. Use:

```bash
source ./scripts/set_context.sh fizz
./scripts/create_harvester_test_job.sh
# → test01, test02, … ; keeps tracking labels (visible in Argo UI under the
#   harvester Application); Prune=false + IgnoreExtraneous so it is not deleted
#   and the app stays Synced
kubectl -n fairagro-advanced-middleware-harvester logs -f job/test01
```

Optional: `PREFIX=manual ./scripts/create_harvester_test_job.sh` or
`-n <namespace> -c <cronjob>`.

**One-shot bootstrap** (requires SOPS access to `environments/<env>/credentials/argocd_secrets.enc.yaml`):

```bash
./scripts/setup_project_in_argocd.sh fizz    # or elise (main — ok without tags)
# draven: only after the first SemVer tag exists (see above)
./scripts/setup_project_in_argocd.sh draven
argocd app sync fairagro-m42-applications
argocd app get fairagro-m42-applications     # confirm targetRevision main vs *
./scripts/check_draven_release_pins.sh       # same gate the release workflow runs
./scripts/compute_next_infra_semver.sh patch # preview next infra SemVer tag
```

The script is idempotent (`argocd app create --upsert -f …`). It applies
`environments/<env>/argocd/fairagro-m42-applications.yaml`. **Do not re-run it while an
emergency pin is active** — it would upsert git `*` / `main` and undo live pins
([docs/ops/emergency-pin.md](docs/ops/emergency-pin.md)). AppProject `fairagro-m42` is
owned by cluster misc (`zalf-argocd-projects`); this script does not create it. If a legacy
`fairagro-m42-application-wrapper` or an experimental `fairagro-m42-root` still
exists, delete it after the new wrapper is healthy. If Root was created after
PR #45 and owns the wrapper, use `--cascade=false` so the wrapper is kept:

```bash
argocd app delete fairagro-m42-root --cascade=false
```

**`local_dev`** remains helm/kind-only (`./scripts/local-dev-*.sh`). It does not
use Argo for this workflow.

As the project contains encrypted secrets (that are also instantiated when running the container),
you will need to enter your personal `gpg` passphrase. This of course requires that your pgp key
is registered within the project. If not, please ask a colleague to add your key. Any colleague
already registered for the project will be able to do so. You can find the list of registered people
within the `public_gpg_keys` folder of an `environment` (so every environment has his own list of
registered users).

## Add a new user to the project ##

To add a new user to the project, please peform these steps.

On the machine where you have generated your key:

- Find out the key fingerprint:

  ```bash
  userid=Any string that identifies yor gpg key
  fingerprint=$(gpg --list-keys -a $userid | sed '2!d' | tr -d " ")
  echo $fingerprint
  ```

  `userid` can be any sub-string that identifies your key, i.e. that is listed behind 'uid' when
  executing `gpg --list-keys` without the `-a` switch. In this example it coud be 'carsten':

  ```bash #2
  pub   ed25519 2023-07-24 [SC]
      CC7B10CE8D78010ABB043F8DB1C462E90012ECFE # the fingerprint
  uid           [ultimate] Carsten Scharfenberg <carsten.scharfenberg@zalf.de>  # the full user id
  sub   cv25519 2023-07-24 [E]
  ```

- Export the public key:

  ```bash
  username=Your_Name
  filename=${fingerprint}_${username}.asc
  gpg --export --armor -o $filename $fingerprint
  ```

  In this case `username` is the actual user name consisting of capitalized first and last name,
  divided by an underscore. E.g.: `Carsten_Scharfenberg`.

With in this project structure on any machine/dev container:

- Import the key manually by:

  ```bash
  gpg --import '<filename>`
  ```

- cd into an environment folder
- Add the public `gpg` key file to the folder `public_gpg_keys` without changing the filename
- Add the key fingerprint to the file `.sops.yaml`
- Re-encrypt all secret files:

  ```bash
  find . -name *.enc.yaml | xargs sops updatekeys
  ```

## `kubectl` cheat sheet ##

find some useful `kubectl` calls below.

### List everything within a namespace ###

The normal call to list 'everything' within a namespace is, e.g.:

```bash
kubectl get all -n fairagro-nextcloud
```

This won't really list everything. Instead you can use:

```bash
kubectl api-resources --namespaced=true --verbs=list -o name \
| xargs -n 1 kubectl get --show-kind --ignore-not-found -n fairagro-nextcloud
```

### Delete 'everything' from a namespace ###

To delete everything from a namespace you would normally call, e.g.

```bash
kubectl delete all --all -n fairagro-nextcloud
```

In fact this does not delete everything, but keeps, e.g., `ConfigMap`s, `Secret`s and
`PersistentVolumeClaim`s. You also could delete the whole namespace to really delete everything:

```bash
kubectl delete namespace fairagro-nextcloud
```

Only this is not ideal for this project, because it will also delete `Roles`s and `RoleBinding`s
that are created by the `zalf-rdm/misc` project and are thus not easy to re-create.

Instead this is a good alternative:

```bash
kubectl delete all,pdb,configmap,secret,pvc,ingress,serviceaccount --all -n fairagro-nextcloud
```

Consider to [list all resources](#list-everything-within-a-namespace) to check if really
everything except `Roles`s and `RoleBindings` has been deleted. Note that kubernetes will
automatically recreate `configmap/kube-root-ca.crt` and `serviceaccount/default`.

### Access kuberenetes cluster using `etcdctl` ###

I case you would like to access the underlying etcd database of kuberentes directly, log
into one of the kubernetes nodes. Then:

```bash
sudo -i
set -a
. /etc/ssl/etdctl
set +a
/usr/local/bin/etcdctl get / --prefix --keys-only  # an example
```

### Create a debug pod from a cronjob ###

We create a `CronJob` that runs the middleware. Sometimes it's useful to manually
create a pod from this job and execute a shell within for debugging. The solution
is not that striaght forward:

First we need to terminate any running/scheduled jobs/pods that have been created
form the cronjob, as otherwise ReadWriteOnce volumes might be mounted serveral times:

```bash
for job in $(kubectl get jobs -o json | jq -r '
  .items[]
  | select(.metadata.ownerReferences[]?.kind == "CronJob")
  | select(.metadata.ownerReferences[]?.name == "basic-middleware-fairagro-basic-middleware")
  | select((.status.succeeded | not) or (.status.succeeded == 0))
  | .metadata.name
'); do
  kubectl delete job "$job"
done
```

Now we can create a debug job and exec into it:

```bash
JOB_NAME=debug-job
# Create a job/pod in suspended state, so it does not run immediately and replace
# the command so it does not do anything but wait.
kubectl create job $JOB_NAME \
  --from=cronjob/basic-middleware-fairagro-basic-middleware \
  -o yaml --dry-run=client | \
yq '
  .spec.suspend = true
  | .spec.template.spec.containers[0].command = ["/bin/sh","-c","sleep infinity"]
  | del(.spec.template.spec.containers[0].args)
' | \
kubectl apply -f -
# Now start the job/pod
kubectl patch job $JOB_NAME -p '{"spec":{"suspend":false}}'
# Wait for the job/pod to be running
kubectl wait --for=condition=ready pod -l batch.kubernetes.io/job-name=$JOB_NAME --timeout=300s
# And exec into it
kubectl exec -it $(kubectl get pod -l batch.kubernetes.io/job-name=$JOB_NAME \
  -o jsonpath='{.items[0].metadata.name}') -- /bin/sh
```
