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
  "https://raw.githubusercontent.com/firelzrd/bore-scheduler/refs/heads/main/patches/testing/0001-linux7.1-rc1-bore-6.8.0-rc1.patch"

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
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/net/tcp/0001-tcp_bbr-v3-update-TCP-bbr-congestion-control-module-.patch?ref_type=heads"

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
  "https://raw.githubusercontent.com/firelzrd/lru_marie/refs/heads/main/patches/testing/0001-linux7.1-rc5-lru_marie-0.7.7.patch"

p "aufs.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.1/misc/0001-aufs-7.1-merge-v20260621.patch"

p "nap.patch" \
  "https://raw.githubusercontent.com/NikoMalik/nap/refs/heads/main/patches/stable/0001-6.18.3-nap-v0.5.1.patch"

p "vhba.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/04-vhba.patch"

p "mm-filemap-retry.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/15-mm-filemap-retry.patch"

p "bfq-mqdeadline-locks.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/03-block.patch"

p "zstd.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.1/NEXT/07-zstd.patch"

p "tcp-write-buffer.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0022-tcp-write-buffer.patch"

p "sched-wait-lifo-accept.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/clearlinux/0001-sched-wait-Do-accept-in-LIFO-order-for-cache-efficie.patch?ref_type=heads"

p "mm-raise-max_map_count-default-value.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/xanmod/0013-XANMOD-mm-Raise-max_map_count-default-value.patch?ref_type=heads"

p "handheld.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.1/misc/0001-handheld.patch"

p "vfs-cache-reclaim-rate.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/xanmod/0012-XANMOD-vfs-Decrease-rate-at-which-vfs-caches-are-rec.patch?ref_type=heads"

p "setlocalversion-remove-tag.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/xanmod/0017-XANMOD-scripts-setlocalversion-remove-tag-for-git-re.patch?ref_type=heads"

p "setlocalversion-move.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/xanmod/0018-XANMOD-scripts-setlocalversion-Move-localversion-fil.patch?ref_type=heads"

p "evdev-use-call-rcu.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/zen/0001-ZEN-input-evdev-Use-call_rcu-when-detaching-client.patch?ref_type=heads"

p "dm-crypt-async-queue.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/zen/0002-ZEN-dm-crypt-Disable-workqueues-for-crypto-ops.patch?ref_type=heads"

p "tcp-skip-collapse.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/net/tcp/0001-tcp-Add-a-sysctl-to-skip-tcp-collapse-processing-whe.patch?ref_type=heads"

p "netfilter-fullcone.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/net/netfilter/0001-netfilter-Add-netfilter-nf_tables-fullcone-support.patch?ref_type=heads"

p "netfilter-flowoffload.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/net/netfilter/0001-netfilter-add-xt_FLOWOFFLOAD-target.patch?ref_type=heads"

p "binder-debug-mask.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/binder/0002-binder-give-binder_alloc-its-own-debug-mask-file.patch?ref_type=heads"

p "stateless-firmware-loading.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/clearlinux/0002-firmware-Enable-stateless-firmware-loading.patch?ref_type=heads"

p "pci-missing-acs-overrides.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/pci_acso/0001-PCI-Enable-overrides-for-missing-ACS-capabilities.patch?ref_type=heads"

p "allow-wake-up-pollfree-gpl.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.1.y-xanmod/binder/0003-wait-allow-to-use-__wake_up_pollfree-from-GPL-module.patch?ref_type=heads"

p "amd_hdmi_frl.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0001-hdmi_frl.patch"

p "surface3.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0002-surface3.patch"

p "surface-mwifiex.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0003-mwifiex.patch"

p "surface-ath10k.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0004-ath10k.patch"

p "surface-sam.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0007-surface-sam.patch"

p "surface-sam-over-hid.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0008-surface-sam-over-hid.patch"

p "surface-typecover.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0010-surface-typecover.patch"

p "surface-shutdown.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0011-surface-shutdown.patch"

p "surface-gpe.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0012-surface-gpe.patch"

p "surface-amd-gpio.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0014-amd-gpio.patch"

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
