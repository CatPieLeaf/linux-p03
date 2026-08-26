#!/usr/bin/env bash
# ==============================================================================
# generate-patches.sh
# For each configured tree, cherry-picks the commits a modified linux fork has
# on top of vanilla linux at that tree's pinned version, then diffs the
# result into a single clean .patch file for patches-p03/.
#
# Usage:  bash sources/generate-patches.sh
#         (can be run from anywhere inside the repo; no arguments)
#
# Fully automatic when nothing conflicts. If a cherry-pick conflicts, drops
# you into an interactive shell inside the vanilla tree to fix it — resolve,
# `git add` the files, `git cherry-pick --continue` (repeat as needed for
# further conflicts in the same tree), then `exit` the shell to resume.
# `git cherry-pick --abort` then `exit` gives up on that tree for this run.
#
# A tree is skipped entirely if patches-p03/<filename> already exists with
# the same Subject — nothing to regenerate.
#
# Add entries with:
#   t "filename.patch" \
#     "https://github.com/user/repo" \
#     "branch-or-tag" \
#     "Subject title" \
#     "vanilla-version"
# ==============================================================================
set -uo pipefail

# Patch mbox identity — matches the packager identity used elsewhere in this repo.
PACKAGER_NAME="CatPieLeaf"
PACKAGER_EMAIL="catpieleaf@proton.me"

declare -A TREE_URL=()
declare -A TREE_SUBJECT=()
declare -A TREE_REF=()
declare -A TREE_KVER=()

t() { TREE_URL["$1"]="$2"; TREE_REF["$1"]="$3"; TREE_SUBJECT["$1"]="$4"; TREE_KVER["$1"]="${5:-}"; }

# ==============================================================================
# TREES
# ==============================================================================

# t "example.patch" \
#   "https://github.com/example/linux-fork" \
#   "branch-or-tag-on-the-fork" \
#   "Example feature merge" \
#   "v7.2"
#
# 3rd arg is the branch/tag/ref on the modified tree. 5th arg is the vanilla
# version THIS tree is diffed against — each tree pins its own, since forks
# can be based on different releases:

t "prjc.patch" \
    "https://gitlab.com/alfredchen/linux-prjc" \
    "linux-7.2.y-prjc" \
    "PRJC 7.2-r0 by alfredchen https://gitlab.com/alfredchen/linux-prjc" \
    "v7.2"

t "lfbmq.patch" \
    "https://gitlab.com/alfredchen/linux-prjc" \
    "linux-7.1.y-lfbmq" \
    "LFBMQ 7.1 by alfredchen https://gitlab.com/alfredchen/linux-prjc" \
    "v7.1"

# ==============================================================================
# — implementation — do not edit below this line —
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"
DEST_DIR="${SCRIPT_DIR}/patches-p03"
WORK_DIR="${SCRIPT_DIR}/.vanilla-patch-work"
VANILLA_DIR="${WORK_DIR}/vanilla"
VANILLA_REMOTE="https://github.com/torvalds/linux.git"

mkdir -p "${DEST_DIR}" "${WORK_DIR}"

FETCH_TIMEOUT=60
FETCH_RETRIES=3

# Every shallow (--depth-bounded) request to a fork's remote has stalled in
# testing, regardless of local repo state, branch, or how fresh/empty the
# target directory was. A plain full (non-shallow) clone is the only thing
# that has ever worked reliably against these hosts — so that's what forks
# get, at the cost of a bigger one-time download. Full clone timeout is
# generous since it can be gigabytes.
CLONE_TIMEOUT=1800

retry_net() {
    local attempt rc
    for attempt in $(seq 1 "${FETCH_RETRIES}"); do
        timeout --foreground "${FETCH_TIMEOUT}" "$@"
        rc=$?
        if [ "${rc}" -eq 0 ]; then
            return 0
        fi
        # 130 = SIGINT (Ctrl+C), 143 = SIGTERM — user aborted, don't retry,
        # don't swallow the interrupt.
        if [ "${rc}" -eq 130 ] || [ "${rc}" -eq 143 ]; then
            exit "${rc}"
        fi
        printf '  (stalled/failed, retry %d/%d)\n' "${attempt}" "${FETCH_RETRIES}" >&2
    done
    return 1
}

# Directory-safe slug for a URL, so trees sharing the same modified-tree URL
# (e.g. prjc.patch and lfbmq.patch both from linux-prjc) share one full
# clone instead of each downloading it separately.
url_slug() {
    printf '%s' "$1" | sed -E 's#^https?://##; s#[^A-Za-z0-9]+#-#g; s/^-+|-+$//g'
}

# More retries than other network ops, and forced HTTP/1.1: this clone has
# repeatedly died mid-transfer with "early EOF" at random points (not a
# server-side stall — a genuinely dropped connection). HTTP/2 stream resets
# on a flaky link are a common cause of exactly that; HTTP/1.1's simpler
# single-stream transfer tends to tolerate instability better.
VANILLA_CLONE_RETRIES=6

if [ ! -d "${VANILLA_DIR}/.git" ]; then
    printf 'Cloning vanilla linux (shallow, one-time)...\n'
    clone_attempt=1
    while :; do
        timeout --foreground "${FETCH_TIMEOUT}" git -c http.version=HTTP/1.1 clone --depth 1 --no-checkout "${VANILLA_REMOTE}" "${VANILLA_DIR}"
        clone_rc=$?
        [ "${clone_rc}" -eq 0 ] && break
        if [ "${clone_rc}" -eq 130 ] || [ "${clone_rc}" -eq 143 ]; then
            exit "${clone_rc}"
        fi
        rm -rf "${VANILLA_DIR}"
        clone_attempt=$((clone_attempt + 1))
        if [ "${clone_attempt}" -gt "${VANILLA_CLONE_RETRIES}" ]; then
            printf 'FAIL — could not clone vanilla linux after %d attempts\n' "${VANILLA_CLONE_RETRIES}"
            exit 1
        fi
        printf '  (stalled/failed, retry %d/%d)\n' "${clone_attempt}" "${VANILLA_CLONE_RETRIES}"
    done
fi

declare -A VANILLA_COMMIT=()   # kver -> resolved commit sha, fetched on demand

# Resolves (fetching the tag first if needed) the commit sha for a vanilla
# version, caching it. Prints the sha on stdout; returns nonzero on failure.
vanilla_commit_for() {
    local kver="$1"
    if [ -n "${VANILLA_COMMIT[${kver}]:-}" ]; then
        printf '%s' "${VANILLA_COMMIT[${kver}]}"
        return 0
    fi
    if ! git -C "${VANILLA_DIR}" rev-parse -q --verify "refs/tags/${kver}" >/dev/null; then
        printf '  Fetching vanilla tag %s...\n' "${kver}" >&2
        if ! retry_net git -C "${VANILLA_DIR}" fetch --depth 1 --force origin \
            "refs/tags/${kver}:refs/tags/${kver}"; then
            return 1
        fi
    fi
    VANILLA_COMMIT["${kver}"]="$(git -C "${VANILLA_DIR}" rev-parse "${kver}^{commit}")"
    printf '%s' "${VANILLA_COMMIT[${kver}]}"
}

write_patch_header() {
    local subject="$1"
    printf 'From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001\n'
    printf 'From: %s <%s>\n' "${PACKAGER_NAME}" "${PACKAGER_EMAIL}"
    printf 'Date: %s\n' "$(date -R -d "$(date +%F)")"
    printf 'Subject: [PATCH] %s\n\n---\n' "${subject}"
}

existing_subject() {
    local patch_file="$1"
    [ -f "${patch_file}" ] || return 1
    grep -m1 '^Subject: \[PATCH\] ' "${patch_file}" | sed -E 's/^Subject: \[PATCH\] //'
}

updated=()
skipped=()
failed=()
declare -A CLONED=()   # url -> fork dir, once cloned this run

for name in "${!TREE_URL[@]}"; do
    url="${TREE_URL[$name]}"
    subject="${TREE_SUBJECT[$name]}"
    ref="${TREE_REF[$name]}"
    kver="${TREE_KVER[$name]}"
    dest="${DEST_DIR}/${name}"

    printf '\n── %s ──────────────────────────────────────────────────────\n' "${name}"

    current_subject="$(existing_subject "${dest}" || true)"
    if [ "${current_subject}" = "${subject}" ]; then
        printf '  Subject unchanged, skipping: %s\n' "${subject}"
        skipped+=("${name}")
        continue
    fi

    vanilla_commit="$(vanilla_commit_for "${kver}")" || {
        printf '  FAIL — could not fetch vanilla tag %s\n' "${kver}"
        failed+=("${name}")
        continue
    }

    fork_dir="${WORK_DIR}/fork-$(url_slug "${url}")"

    if [ -z "${CLONED[${url}]:-}" ]; then
        # Full, non-shallow clone — the only thing that's worked reliably
        # against these hosts. Shared across every tree using this URL.
        printf '  Cloning modified tree (full, shared across trees using this URL): %s\n' "${url}"
        rm -rf "${fork_dir}"
        clone_attempt=1
        clone_ok=1
        while :; do
            timeout --foreground "${CLONE_TIMEOUT}" git clone --no-checkout "${url}" "${fork_dir}"
            clone_rc=$?
            [ "${clone_rc}" -eq 0 ] && break
            if [ "${clone_rc}" -eq 130 ] || [ "${clone_rc}" -eq 143 ]; then
                exit "${clone_rc}"
            fi
            rm -rf "${fork_dir}"
            clone_attempt=$((clone_attempt + 1))
            if [ "${clone_attempt}" -gt "${FETCH_RETRIES}" ]; then
                printf '  FAIL — could not clone modified tree after %d attempts\n' "${FETCH_RETRIES}"
                clone_ok=0
                break
            fi
            printf '  (stalled/failed, retry %d/%d)\n' "${clone_attempt}" "${FETCH_RETRIES}"
        done
        if [ "${clone_ok}" -eq 0 ]; then
            failed+=("${name}")
            continue
        fi
        CLONED["${url}"]="${fork_dir}"
    fi

    modified_ref="refs/remotes/origin/${ref}"
    if ! git -C "${fork_dir}" rev-parse -q --verify "${modified_ref}" >/dev/null; then
        modified_ref="refs/tags/${ref}"
        if ! git -C "${fork_dir}" rev-parse -q --verify "${modified_ref}" >/dev/null; then
            printf '  FAIL — ref "%s" not found in modified tree\n' "${ref}"
            failed+=("${name}")
            continue
        fi
    fi

    # fork_dir is a full clone of every branch in this repo, sharing one
    # object store — the real vanilla commit is almost certainly already in
    # there too (e.g. prjc's own branch is built directly on it), so do the
    # cherry-pick/diff entirely inside fork_dir with no further transfer at
    # all, rather than pulling the fork's history into vanilla_dir (which,
    # even over the local filesystem, still means repacking possibly
    # millions of objects).
    if git -C "${fork_dir}" cat-file -e "${vanilla_commit}" 2>/dev/null; then
        work_dir="${fork_dir}"
        vanilla_ref="${vanilla_commit}"
    else
        printf '  Vanilla commit not present in fork clone — bridging locally...\n'
        git -C "${VANILLA_DIR}" remote remove modified >/dev/null 2>&1 || true
        git -C "${VANILLA_DIR}" remote add modified "${fork_dir}"
        if ! git -C "${VANILLA_DIR}" fetch modified "${modified_ref}"; then
            printf '  FAIL — could not bridge fork clone into vanilla\n'
            failed+=("${name}")
            continue
        fi
        work_dir="${VANILLA_DIR}"
        vanilla_ref="refs/tags/${kver}"
        modified_ref="FETCH_HEAD"
    fi

    git -C "${work_dir}" cherry-pick --abort >/dev/null 2>&1 || true
    git -C "${work_dir}" checkout --force --detach "${vanilla_ref}"
    git -C "${work_dir}" reset --hard "${vanilla_ref}"
    git -C "${work_dir}" clean -fdx

    # Merge-base, not the pinned kver directly, bounds the cherry-pick range
    # — the fork's actual base may be an earlier point release.
    base="$(git -C "${work_dir}" merge-base "${vanilla_ref}" "${modified_ref}" 2>/dev/null || true)"

    if [ -z "${base}" ]; then
        printf '  FAIL — no common history between %s and modified tree\n' "${kver}"
        failed+=("${name}")
        continue
    fi

    range="${base}..${modified_ref}"
    commit_count="$(git -C "${work_dir}" rev-list --count "${range}" 2>/dev/null || echo 0)"

    if [ "${commit_count}" -eq 0 ]; then
        printf '  FAIL — no commits between %s and modified tree\n' "${kver}"
        failed+=("${name}")
        continue
    fi

    printf '  Cherry-picking %d commit(s) onto vanilla...\n' "${commit_count}"
    if ! git -C "${work_dir}" cherry-pick --allow-empty -x "${range}" >/dev/null 2>&1; then
        printf '\n  Conflict — opening a shell in %s\n' "${work_dir}"
        printf '  Fix it, "git add" the files, "git cherry-pick --continue" (repeat if\n'
        printf '  more conflicts follow), then "exit". Or "git cherry-pick --abort" then\n'
        printf '  "exit" to give up on this tree.\n\n'
        ( cd "${work_dir}" && bash )

        if git -C "${work_dir}" rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null; then
            printf '  Still unresolved, skipping %s.\n' "${name}"
            failed+=("${name}")
            continue
        fi
        if [ "$(git -C "${work_dir}" rev-parse HEAD)" = "$(git -C "${work_dir}" rev-parse "${vanilla_ref}")" ]; then
            printf '  Aborted, skipping %s.\n' "${name}"
            failed+=("${name}")
            continue
        fi
    fi

    tmp="$(mktemp)"
    write_patch_header "${subject}" > "${tmp}"
    git -C "${work_dir}" diff "${vanilla_ref}" HEAD >> "${tmp}"

    if [ -f "${dest}" ] && cmp -s "${dest}" "${tmp}"; then
        printf '  Unchanged.\n'
        rm -f "${tmp}"
    else
        mv "${tmp}" "${dest}"
        printf '  Wrote: %s\n' "$(realpath --relative-to="${REPO_ROOT}" "${dest}")"
        updated+=("${name}")
    fi
done

printf '\n────────────────────────────────────────────────────────────\n'
printf ' Updated : %d\n' "${#updated[@]}"
printf ' Skipped : %d\n' "${#skipped[@]}"
printf ' Failed  : %d\n' "${#failed[@]}"
printf '────────────────────────────────────────────────────────────\n'

if [ "${#failed[@]}" -gt 0 ]; then
    printf '\nWARNING — failed trees:\n'
    for f in "${failed[@]}"; do
        printf '  %s\n' "${f}"
    done
fi

printf '\nCleaning up work dir: %s\n' "${WORK_DIR}"
rm -rf "${WORK_DIR}"
