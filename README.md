# FAIRagro m4.2_infrastructure #

Infrastructure-as-Code to deploy services needed by measure 4.2

## How to deal with this project ##

This project delivers a `vscode` dev container that contains all tools needed. To use that container
you need a running docker installation and choose 'Clone in Volume' after opening it in `vscode`.
It will take quite some time to build the container.

As the project contains encrypted secrets (that are also instantiated when running the container),
you will need to enter your personal `gpg` passphrase. This of course requires that your pgp key
is registered within the project. If not, please ask a colleague to add your key. Any colleague
already registered for the project will be able to do so. You can find the list of registered people
within the `public_gpg_keys` folder of an `environment` (so every environment has his own list of
registered users).

## Add a new user to the project ##

To add a new user to the project, please peform these steps.

On the machine where you have generated your key:

* Find out the key fingerprint:

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

* Export the public key:

  ```bash
  username=Your_Name
  filename=${fingerprint}_${username}.asc
  gpg --export --armor -o $filename $fingerprint
  ```

  In this case `username` is the actual user name consisting of capitalized first and last name,
  divided by an underscore. E.g.: `Carsten_Scharfenberg`.

With in this project structure on any machine/dev container:

* Import the key manually by:

  ```bash
  gpg --import '<filename>`
  ```

* cd into an environment folder
* Add the public `gpg` key file to the folder `public_gpg_keys` without changing the filename
* Add the key fingerprint to the file `.sops.yaml`
* Re-encrypt all secret files:

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
