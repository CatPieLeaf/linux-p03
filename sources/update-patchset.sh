#!/usr/bin/env bash
# ==============================================================================
# update-patchset.sh
# Downloads patches from upstream URLs, saves them into ./patchset/ and
# ./patchset-nvidia/, and commits any changes to the repo.
#
# Usage:  bash sources/update-patchset.sh
#         (can be run from anywhere inside the repo)
#
# Add entries with:
#   p   "filename" \
#       "url"
#   pnv "filename" \
#       "url"
# ==============================================================================
set -euo pipefail

declare -A PATCHSET=()
declare -A PATCHSET_NVIDIA=()

p()   { PATCHSET["$1"]="$2"; }
pnv() { PATCHSET_NVIDIA["$1"]="$2"; }

# ==============================================================================
# PATCHSET
# ==============================================================================

p "clang-polly.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/7.1/misc/0001-clang-polly.patch"

p "dkms-clang.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/7.1/misc/dkms-clang.patch"

p "acpi-call.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/7.1/misc/0001-acpi-call.patch"

p "bore.patch" \
  "https://raw.githubusercontent.com/firelzrd/bore-scheduler/refs/heads/main/patches/stable/linux-7.1-bore/0001-linux7.1-rc1-bore-6.6.3.patch"

p "adios.patch" \
  "https://raw.githubusercontent.com/firelzrd/adios/refs/heads/main/patches/stable/0001-linux6.19.3-ADIOS-3.2.0.patch"

p "cgroup-vram.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0017-cgroup-vram.patch"

p "mm-mmput-async.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0016-mm-mmput-async.patch"

p "mm-libs-grow-down.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0015-mm-libs-grow-down.patch"

p "sched-ratelimit-yield.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0014-sched-ratelimit-yield.patch"

p "sched-better-idle-balance.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0011-sched-better-idle-balance.patch"

p "posted-msi-enable-by-default.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0010-posted-msi-enable-by-default.patch"

p "bbr3.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/12-bbr3.patch"

p "disable-split-lock.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0006-disable-split-lock.patch"

p "mm_lazy_rss_stat.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0004-mm_lazy_rss_stat.patch"

p "openRGB.patch" \
  "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/7.1/0014-OpenRGB.patch"

p "optimize_harder_O3.patch" \
  "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/7.1/0013-optimize_harder_O3.patch"

p "misc-additions.patch" \
  "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/7.1/0012-misc-additions.patch"

p "poc-selector.patch" \
  "https://raw.githubusercontent.com/firelzrd/poc-selector/refs/heads/main/patches/stable/0001-7.1-rc1-poc-selector-v2.6.2r2.patch"

p "add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch" \
  "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/7.1/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch"

p "lru_marie.patch" \
  "https://raw.githubusercontent.com/firelzrd/lru_marie/refs/heads/main/patches/testing/0001-linux7.1-rc5-lru_marie-0.5.0r3.patch"

p "aufs.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.1/misc/0001-aufs-7.1-merge-v20260525.patch"

p "nap.patch" \
  "https://raw.githubusercontent.com/firelzrd/nap/refs/heads/main/patches/stable/0001-6.18.3-nap-v0.5.0.patch"

p "vhba.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/04-vhba.patch"

p "mm-filemap-retry.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/15-mm-filemap-retry.patch"

p "bfq-mqdeadline-locks.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/03-block.patch"

p "zstd.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/07-zstd.patch"

# ==============================================================================
# PATCHSET-NVIDIA
# ==============================================================================

pnv "add-IBT-support.patch" \
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.1/misc/nvidia/0001-Add-IBT-support.patch"

pnv "fix-dsc.patch" \
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.1/misc/nvidia/0002-fix-dsc-correct-RC-parameter-tables-to-match-VESA-DS.patch"

pnv "fix-dp.patch" \
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.1/misc/nvidia/0004-fix-dp-add-Bigscreen-Beyond-VR-headset-to-WAR-databa.patch"

# ==============================================================================
# — implementation — do not edit below this line —
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"
SCRIPT_RELPATH="$(realpath --relative-to="${REPO_ROOT}" "${BASH_SOURCE[0]}")"

changed=()
identical=()
failed=()

process_section() {
    local section_dir="$1"
    local -n _entries="$2"
    local dest_dir="${SCRIPT_DIR}/${section_dir}"

    printf '\n── %s ──────────────────────────────────────────────────────\n' "${section_dir}"
    mkdir -p "${dest_dir}"

    for name in "${!_entries[@]}"; do
        local url="${_entries[$name]}"
        local dest="${dest_dir}/${name}"
        local tmp
        tmp="$(mktemp)"

        printf '  %-58s ' "${name}"

        if ! curl -fsSL --retry 3 "${url}" -o "${tmp}" 2>/dev/null; then
            printf 'FAIL\n'
            failed+=("${section_dir}/${name}")
            rm -f "${tmp}"
            continue
        fi

        if [ -f "${dest}" ] && cmp -s "${dest}" "${tmp}"; then
            printf '=  (unchanged)\n'
            identical+=("${section_dir}/${name}")
            rm -f "${tmp}"
        else
            mv "${tmp}" "${dest}"
            printf '*  (updated)\n'
            changed+=("$(realpath --relative-to="${REPO_ROOT}" "${dest}")")
        fi
    done
}

process_section "patchset"        PATCHSET
process_section "patchset-nvidia" PATCHSET_NVIDIA

printf '\n────────────────────────────────────────────────────────────\n'
printf ' Updated  : %d\n' "${#changed[@]}"
printf ' Identical: %d\n' "${#identical[@]}"
printf ' Failed   : %d\n' "${#failed[@]}"
printf '────────────────────────────────────────────────────────────\n'

if [ "${#failed[@]}" -gt 0 ]; then
    printf '\nWARNING — failed downloads:\n'
    for f in "${failed[@]}"; do
        printf '  %s\n' "${f}"
    done
fi

if [ "${#changed[@]}" -eq 0 ]; then
    printf '\nNo changes — nothing to commit.\n'
    exit 0
fi

commit_date="$(date '+%Y-%m-%d')"
commit_body="$(printf 'Changed (%s):\n' "${commit_date}")"
for f in "${changed[@]}"; do
    commit_body+="$(printf '  %s\n' "${f}")"
done

git -C "${REPO_ROOT}" add "${changed[@]}" "${SCRIPT_RELPATH}"
git -C "${REPO_ROOT}" commit -m "chore: update patchset" -m "${commit_body}"

printf '\nCommitted.\n'
