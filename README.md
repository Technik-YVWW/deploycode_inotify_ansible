# ocm-deploy

`ocm-deploy` watches configured filesystem paths and runs ordered Ansible playbook chains after a change. The playbooks may act locally or remotely.

```text
filesystem event
-> debounce
-> enabled config
-> per-config lock
-> ordered Ansible playbook chain
-> local or remote target
```

The name describes the component's role in the OCM system. The current trigger mechanism remains `inotifywait`, while the generic runner is intentionally independent from any single deployment payload.

## Requirements

Runtime tools:

- `ansible-playbook` (`ansible-core` or full `ansible`)
- `inotifywait` (`inotify-tools` on Debian)
- `flock` (`util-linux` on Debian)
- `pkill` (`procps` on Debian)
- `realpath` (`coreutils` on Debian)

The installer additionally uses standard tools such as `install`, `readlink`, `dirname`, and `basename`.

## Install

```sh
sudo ./install.sh
```

The installer creates the `/etc/ocm-deploy` directory structure, installs the runtime scripts and library, installs the systemd unit, and copies missing skeleton files without overwriting local configuration.

## Configuration layout

```text
/etc/ocm-deploy/
├── configs-available/
├── configs-enabled/
├── playbooks/
├── playbook-vars/
└── roles/
```

Create a config from the installed skeleton:

```sh
sudo cp /etc/ocm-deploy/configs-available/_skeleton.conf \
  /etc/ocm-deploy/configs-available/example.conf
sudo editor /etc/ocm-deploy/configs-available/example.conf
sudo ln -s ../configs-available/example.conf \
  /etc/ocm-deploy/configs-enabled/example.conf
```

A config defines one watch directory and a consecutive, ordered playbook chain:

```text
inotify_watchdir:/srv/git/example.git
playbook1:git-pull
vars_playbook1:example
playbook2:test-ping
vars_playbook2:example
```

Each `playbookN` requires a matching `vars_playbookN`. Numbering must remain consecutive. The referenced vars file must contain a top-level `target_server` value because `ocm-deploy` creates a temporary Ansible inventory for each playbook execution.

## Validate a config once

Before enabling the long-running watcher, execute a config directly:

```sh
sudo ocm-deploy-test example
```

For development directly from the repository root:

```sh
sh ./ocm-deploy-test _skeleton
```

The test command uses `/tmp/ocm-deploy-test` for transient state unless `OCM_DEPLOY_RUNTIME_DIR` is explicitly set.

## Enable the service

```sh
sudo systemctl enable --now ocm-deploy
```

Runtime state is stored below `/run/ocm-deploy`:

```text
/run/ocm-deploy/
├── inv/
├── locks/
└── pids/
```

A separate `flock` lock exists for each enabled config. This prevents duplicate concurrent runs of the same chain while allowing independent configs to run in parallel.

## Runtime semantics

- A watcher reacts to `modify`, `create`, `delete`, and `move` events below its configured directory.
- Events are debounced for five seconds by default. Override this with `OCM_DEPLOY_DEBOUNCE_SECONDS`.
- The watcher runs the configured chain after a filesystem event. It does **not** perform an automatic initial deployment merely because the service starts.
- Use `ocm-deploy-test <config>` for an explicit one-shot execution and validation.

## Development checks

```sh
sh ./check-shell.sh
```

The script always runs `dash -n` and `bash -n`. It additionally runs `shellcheck` and `shfmt -d` when those tools are installed.

## Migration from the pre-production name

The modernization branch used the temporary name `deploycode`. Before installing `ocm-deploy` on a host that already contains that earlier test version, remove or disable the obsolete `deploycode-inotify.service` and migrate any local files from `/etc/deploycode` to `/etc/ocm-deploy`.

## Planned first extension

The first planned production extension is a directed local path-sync playbook for the Servermoench boot and rescue media:

```text
/boot    -> /efi -> /efi2
/rescue1 -> /rescue2
```

That sync logic belongs in a dedicated idempotent playbook and vars file. The generic event runner should remain independent from the concrete synchronization policy.
