#!/bin/sh
# Sanity tests for usr/lib/libDeploy.
# Purpose:
# - catch basic regressions after renaming/refactoring
# - test helper functions without touching /etc or requiring real Ansible targets
# - keep this as an explicit developer/refactor test, not as a half-hidden formatter hook

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$repo_root"

lib_file="./usr/lib/libDeploy"

[ -r "$lib_file" ] || {
	echo "FAIL: can not read $lib_file" >&2
	exit 1
}

# shellcheck source=/dev/null
. "$lib_file"

tests_run=0
tests_failed=0

pass() {
	tests_run=$((tests_run + 1))
	echo "ok  - $1"
}

fail() {
	tests_run=$((tests_run + 1))
	tests_failed=$((tests_failed + 1))
	echo "FAIL - $1" >&2
}

assert_eq() {
	name="$1"
	expected="$2"
	actual="$3"

	if [ "$expected" = "$actual" ]; then
		pass "$name"
	else
		fail "$name: expected '$expected', got '$actual'"
	fi
}

assert_file_exists() {
	name="$1"
	path="$2"

	if [ -f "$path" ]; then
		pass "$name"
	else
		fail "$name: missing file '$path'"
	fi
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

playbook_dir="$tmpdir/etc/ocm-deploy/playbooks"
vars_dir="$tmpdir/etc/ocm-deploy/playbook-vars"
config_dir="$tmpdir/etc/ocm-deploy/configs-available"
watch_dir="$tmpdir/watch"
fake_bin="$tmpdir/bin"
runtime_dir="$tmpdir/run"

mkdir -p "$playbook_dir" "$vars_dir" "$config_dir" "$watch_dir" "$fake_bin" "$runtime_dir"

cat >"$playbook_dir/git-pull.yml" <<'YAML'
---
- hosts: all
  gather_facts: false
  tasks:
    - debug:
        msg: test
YAML

cat >"$playbook_dir/test-ping.yml" <<'YAML'
---
- hosts: all
  gather_facts: false
  tasks:
    - ping:
YAML

cat >"$vars_dir/git-pull-local.yml" <<'YAML'
---
target_server: test-host.local
YAML

cat >"$config_dir/git-pull.conf" <<EOF_CONF
# test config
inotify_watchdir: $watch_dir
playbook1: git-pull
vars_playbook1: git-pull-local
EOF_CONF

# Keep one non-yml file to make sure extension counting is useful.
touch "$playbook_dir/README.txt"

echo "== libDeploy sanity test =="
echo

assert_file_exists "local libDeploy exists" "$lib_file"

canonical_result=$(canonical_dir "$playbook_dir")
assert_eq "canonical_dir returns physical playbook path" "$playbook_dir" "$canonical_result"

count_all=$(count_folder_files "$playbook_dir")
assert_eq "count_folder_files counts all direct entries" "3" "$count_all"

count_yml=$(count_folder_files "$playbook_dir" "yml")
assert_eq "count_folder_files counts yml entries" "2" "$count_yml"

config_watchdir=$(get_config_value "$config_dir/git-pull.conf" "inotify_watchdir")
assert_eq "get_config_value reads inotify_watchdir" "$watch_dir" "$config_watchdir"

config_playbook=$(get_config_value "$config_dir/git-pull.conf" "playbook1")
assert_eq "get_config_value reads playbook1" "git-pull" "$config_playbook"

vars_target=$(get_yml_value "$vars_dir/git-pull-local.yml" "target_server")
assert_eq "get_yml_value reads target_server" "test-host.local" "$vars_target"

iterated_count=0
for file in "$playbook_dir"/*; do
	[ -e "$file" ] || [ -L "$file" ] || continue
	iterated_count=$((iterated_count + 1))
done
assert_eq "safe glob iteration over playbook dir" "3" "$iterated_count"

# Test watch_for_run_pb in test mode without real Ansible.
# We inject a fake ansible-playbook binary through the tool_ansible variable.
cat >"$fake_bin/ansible-playbook" <<'FAKE_ANSIBLE'
#!/bin/sh
{
	echo "ansible-playbook called with:"
	printf '%s\n' "$@"
} >>"${LIBDEPLOY_SANITY_LOG:?}"
exit 0
FAKE_ANSIBLE
chmod +x "$fake_bin/ansible-playbook"

LIBDEPLOY_SANITY_LOG="$tmpdir/ansible.log"
export LIBDEPLOY_SANITY_LOG

tool_ansible="$fake_bin/ansible-playbook"
export OCM_DEPLOY_RUNTIME_DIR="$runtime_dir"

if command -v flock >/dev/null 2>&1; then
	if watch_for_run_pb "$config_dir/git-pull.conf" "$playbook_dir/" "$vars_dir/" 1 >/dev/null; then
		pass "watch_for_run_pb executes one configured playbook in test mode"
	else
		fail "watch_for_run_pb executes one configured playbook in test mode"
	fi

	if grep -q "$playbook_dir/git-pull.yml" "$LIBDEPLOY_SANITY_LOG"; then
		pass "fake ansible received expected playbook path"
	else
		fail "fake ansible received expected playbook path"
	fi

	if grep -q "$vars_dir/git-pull-local.yml" "$LIBDEPLOY_SANITY_LOG"; then
		pass "fake ansible received expected vars path"
	else
		fail "fake ansible received expected vars path"
	fi
else
	echo "skip - watch_for_run_pb test needs flock"
fi

echo
echo "Tests run:    $tests_run"
echo "Tests failed: $tests_failed"

[ "$tests_failed" -eq 0 ]
