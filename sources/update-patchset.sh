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
declare -A PATCHES_P03=()

p()   { PATCHSET["$1"]="$2"; }
pnv() { PATCHSET_NVIDIA["$1"]="$2"; }
p03() { PATCHES_P03["$1"]="$2"; }

# ==============================================================================
# PATCHSET
# ==============================================================================

# STILL 7.1
p "clang-polly.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/7.1/misc/0001-clang-polly.patch"

p "dkms-clang.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.2/misc/dkms-clang.patch"

p "acpi-call.patch" \
  "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.2/misc/0001-acpi-call.patch"

p "adios.patch" \
  "https://raw.githubusercontent.com/firelzrd/adios/refs/heads/main/patches/stable/0001-linux6.18.3-ADIOS-3.3.0.patch"

p "cgroup-vram.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0017-cgroup-vram.patch"

p "mm-mmput-async.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0016-mm-mmput-async.patch"

p "mm-libs-grow-down.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0015-mm-libs-grow-down.patch"

p "sched-better-idle-balance.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0011-sched-better-idle-balance.patch"

# STILL 7.1
p "posted-msi-enable-by-default.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0010-posted-msi-enable-by-default.patch"

p "disable-split-lock.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0006-disable-split-lock.patch"

p "mm_lazy_rss_stat.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0004-mm_lazy_rss_stat.patch"

p "openRGB.patch" \
  "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/7.2/0014-OpenRGB.patch"

p "add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch" \
  "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/7.2/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch"

p "lru_marie.patch" \
  "https://raw.githubusercontent.com/firelzrd/lru_marie/refs/heads/main/patches/testing/0001-linux7.2-rc1-lru_marie-0.11.1.patch"

p "nap.patch" \
  "https://raw.githubusercontent.com/NikoMalik/nap/refs/heads/main/patches/stable/0001-6.18.3-nap-v0.5.1.patch"

p "mm-filemap-retry.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.2/NEXT/15-mm-filemap-retry.patch"

p "bfq-mqdeadline-locks.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.2/NEXT/03-block.patch"

p "zstd.patch" \
  "https://raw.githubusercontent.com/babiulep/my-kernel-patches/refs/heads/main/PATCHES/7.2/NEXT/07-zstd.patch"

p "tcp-write-buffer.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0022-tcp-write-buffer.patch"

p "sched-wait-lifo-accept.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/clearlinux/0001-sched-wait-Do-accept-in-LIFO-order-for-cache-efficie.patch?ref_type=heads"

p "mm-raise-max_map_count-default-value.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/xanmod/0013-XANMOD-mm-Raise-max_map_count-default-value.patch?ref_type=heads"

p "bbr3.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/net/tcp/0001-tcp_bbr-v3-update-TCP-bbr-congestion-control-module-.patch?ref_type=heads"

p "vfs-cache-reclaim-rate.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/xanmod/0012-XANMOD-vfs-Decrease-rate-at-which-vfs-caches-are-rec.patch?ref_type=heads"

p "setlocalversion-remove-tag.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/xanmod/0017-XANMOD-scripts-setlocalversion-remove-tag-for-git-re.patch?ref_type=heads"

p "setlocalversion-move.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/xanmod/0018-XANMOD-scripts-setlocalversion-Move-localversion-fil.patch?ref_type=heads"

p "evdev-use-call-rcu.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/zen/0001-ZEN-input-evdev-Use-call_rcu-when-detaching-client.patch?ref_type=heads"

p "dm-crypt-async-queue.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/zen/0002-ZEN-dm-crypt-Disable-workqueues-for-crypto-ops.patch?ref_type=heads"

p "tcp-skip-collapse.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/net/tcp/0001-tcp-Add-a-sysctl-to-skip-tcp-collapse-processing-whe.patch?ref_type=heads"

p "netfilter-flowoffload.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/net/netfilter/0001-netfilter-add-xt_FLOWOFFLOAD-target.patch?ref_type=heads"

p "netfilter-fullcone.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/net/netfilter/0001-netfilter-Add-netfilter-nf_tables-fullcone-support.patch?ref_type=heads"

p "binder-debug-mask.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/binder/0002-binder-give-binder_alloc-its-own-debug-mask-file.patch?ref_type=heads"

p "stateless-firmware-loading.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/clearlinux/0002-firmware-Enable-stateless-firmware-loading.patch?ref_type=heads"

p "pci-missing-acs-overrides.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/pci_acso/0001-PCI-Enable-overrides-for-missing-ACS-capabilities.patch?ref_type=heads"

p "allow-wake-up-pollfree-gpl.patch" \
  "https://gitlab.com/xanmod/linux-patches/-/raw/master/linux-7.2.y-xanmod/binder/0003-wait-allow-to-use-__wake_up_pollfree-from-GPL-module.patch?ref_type=heads"

p "surface3.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0002-surface3.patch"

p "surface-ath10k.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0004-ath10k.patch"

p "surface-sam.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0007-surface-sam.patch"

p "surface-sam-over-hid.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0008-surface-sam-over-hid.patch"

p "surface-typecover.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0010-surface-typecover.patch"

p "surface-gpe.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0012-surface-gpe.patch"

p "surface-amd-gpio.patch" \
  "https://raw.githubusercontent.com/linux-surface/linux-surface/refs/heads/master/patches/6.19/0014-amd-gpio.patch"

p "cambyses.patch" \
  "https://raw.githubusercontent.com/firelzrd/cambyses/refs/heads/main/patches/0001-7.2.0-rc4-cambyses-v0.6.0.patch"

# STILL 7.1
p "zram-ir.patch" \
  "https://raw.githubusercontent.com/firelzrd/zram-ir/refs/heads/main/patches/0001-linux7.1-rc1-zram-ir-1.3.patch"

p "amdgpu-max-power-limit-115pct.patch" \
  "https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.2/0023-amdgpu-max-power-limit-115pct.patch"

# ==============================================================================
# PATCHSET-NVIDIA
# ==============================================================================

pnv "fix-dsc.patch" \
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.2/misc/nvidia/0002-fix-dsc-correct-RC-parameter-tables-to-match-VESA-DS.patch"

pnv "fix-dp.patch" \
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.2/misc/nvidia/0003-fix-dp-add-Bigscreen-Beyond-VR-headset-to-WAR-databa.patch"

# ==============================================================================
# PATCHES-P03
#
# Downloaded like the others, then post-processed by fixup_aufs() below.
# Do not hand-edit the downloaded file: the next run overwrites it.
# ==============================================================================

p03 "aufs.patch" \
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/refs/heads/master/7.2/misc/0001-aufs-7.2-merge-v20260907.patch"

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

        # Post-process before comparing, so a patch p03 has to adjust still
        # reports "unchanged" when upstream has not moved.
        if declare -F "fixup_${name%.patch}" >/dev/null; then
            "fixup_${name%.patch}" "${tmp}" || {
                printf 'FAIL (fixup)\n'
                failed+=("${section_dir}/${name} (fixup)")
                rm -f "${tmp}"
                continue
            }
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


# ------------------------------------------------------------------------------
# fixup_aufs — replace three aufs hunks with p03's reduced-context versions.
#
# Those hunks collide with openSUSE's patches.suse/vfs-add-super_operations-
# get_inode_dev, which rewrites the very same lines of fs/proc/nommu.c,
# fs/proc/task_nommu.c and include/linux/fs/super_types.h. openSUSE's series is
# applied before p03's, so upstream aufs then meets context SUSE has already
# edited and all three hunks fail. Measured on a SUSE-patched 7.2.6 tree: raw
# upstream fails 3 hunks, these versions fail 0 -- and 0 on vanilla too, at
# --fuzz=0.
#
# The replacements are verbatim, not computed: SUSE perturbs both the leading
# and trailing context of the nommu hunks but only the leading context of
# super_types.h, so there is no mechanical rule that produces all three. Each is
# guarded by the sha256 of the upstream section it replaces; if aufs ever
# rewrites one, the guard trips and the build is left alone for a human.
# ------------------------------------------------------------------------------
fixup_aufs() {
    local f="$1"
    [ -f "${f}" ] || return 0

    python3 - "${f}" <<'PYEOF'
import hashlib, re, sys

path = sys.argv[1]

# upstream section sha256 (first 16 hex) -> replacement section
REPL = {
    "fs/proc/nommu.c": ("45ff7ff181b5d0e7", """diff --git a/fs/proc/nommu.c b/fs/proc/nommu.c
index c6e7ebc63..12c340dcd 100644
--- a/fs/proc/nommu.c
+++ b/fs/proc/nommu.c
@@ -42 +42 @@
-		struct inode *inode = file_inode(region->vm_file);
+		struct inode *inode = file_user_inode(region->vm_file);
"""),
    "fs/proc/task_nommu.c": ("2a2140d8c32c2ac6", """diff --git a/fs/proc/task_nommu.c b/fs/proc/task_nommu.c
index d362919f4..79a2590d4 100644
--- a/fs/proc/task_nommu.c
+++ b/fs/proc/task_nommu.c
@@ -140 +140 @@
-		struct inode *inode = file_inode(vma->vm_file);
+		struct inode *inode = file_user_inode(vma->vm_file);
"""),
    "include/linux/fs/super_types.h": ("ccff62230129e8b2", """diff --git a/include/linux/fs/super_types.h b/include/linux/fs/super_types.h
index ef7941e9d..b866d11ca 100644
--- a/include/linux/fs/super_types.h
+++ b/include/linux/fs/super_types.h
@@ -132,3 +132,8 @@
+
+#if IS_ENABLED(CONFIG_BLK_DEV_LOOP) || IS_ENABLED(CONFIG_BLK_DEV_LOOP_MODULE)
+	/* and aufs */
+	struct file *(*real_loop)(struct file *);
+#endif
 };

 struct super_block {
"""),
}

txt = open(path, errors="surrogateescape").read()
parts = re.split(r"(?m)^(diff --git a/\S+ b/\S+)$", txt)
out = [parts[0]]
done, stale = [], []

for i in range(1, len(parts), 2):
    hdr, body = parts[i], parts[i + 1]
    fn = re.match(r"diff --git a/(\S+) b/", hdr).group(1)
    sec = hdr + "\n" + body.lstrip("\n")
    if fn in REPL:
        want, repl = REPL[fn]
        got = hashlib.sha256(sec.encode("utf-8", "surrogateescape")).hexdigest()[:16]
        if got == want:
            sec = repl
            done.append(fn)
        else:
            stale.append(f"{fn} (sha {got}, expected {want})")
    out.append(sec)

if stale:
    sys.stderr.write(
        "    aufs: FIXUP GUARD TRIPPED - upstream rewrote:\n"
        + "".join(f"      {x}\n" for x in stale)
        + "    Re-derive the reduced-context hunks and update fixup_aufs(),\n"
        "    then re-test against an openSUSE tree. Leaving the file untouched.\n")
    sys.exit(1)

open(path, "w", errors="surrogateescape").write("".join(out))
sys.stderr.write("    aufs: reduced-context hunks applied (" + ", ".join(done) + ")\n")
PYEOF
}

process_section "patchset"        PATCHSET
process_section "patchset-nvidia" PATCHSET_NVIDIA
process_section "patches-p03"     PATCHES_P03

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
