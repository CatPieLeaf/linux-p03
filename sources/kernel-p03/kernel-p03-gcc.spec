
#     |\|\|\                       ________
#    _|_|_|_|_____________________|________ \
#  / ---------------------------|-|-|_---- \ \
# | |                                     | | |
# | |                                     | |_/
# |_|                                     | |
# | |     =========        =========      | |     LINUX    LINUX   LINUX
# |_|         =====            =====      | |     NU   L  L   N L      L
# | |                                     | |     XLINUX  I  I  X   LIN
# | |                        =            | |     IN      N L   U      N
# | |             ============            | |     UX       UXLIN   LINUX
# | |           ==          =             | |
# | |_____                           _____| |
# |    =   \                       //  =  \ |
# |  ===== |                       ||  =  | |
# |    =   |_______________________|\  =  / |
#  \________________|_|_|_|________________/

# ==============================================================================
# Build system overrides
# ==============================================================================
%define __spec_install_post   %{__os_install_post}
%define _build_id_links       none
%define _default_patch_fuzz   2
%define _disable_source_fetch 0
%define make_build            make %{?_clang_args} %{?_smp_mflags}
%undefine __brp_mangle_shebangs
%undefine _auto_set_build_flags

# ==============================================================================
# Feature flags
# ==============================================================================

# 0 = no debuginfo, no frame pointers (default)
# 1 = debuginfo + DWARF5 + frame pointers (required for RPM Fusion / Fedora)
%define _build_debug 0

%if !%{_build_debug}
  %define debug_package %{nil}
  %undefine _include_frame_pointers
%endif

# Compiler: set exactly one to 1. Setting both or neither aborts the build.
%define _build_clang 0
%define _build_gcc   1

# LTO: set at most one to 1.
%define _build_lto 0
%define _lto_thin  0
%define _lto_full  0

# Optimization level: 0=size, 2=O2, 3=O3, other=default
%define _opt_level 3

# Secure Boot: generates a per-machine MOK key on first install.
# Enroll once with: mokutil --import /etc/kernel/certs/p03-kernel/mok.der
%define _build_secureboot 1

# Tickrate: 100, 250, 300, 500, 600, 750, 1000. Invalid value falls back to 1000.
%define _hz_tick 750

# x86_64 ISA level: 1-4. Invalid value falls back to x86_64_v3.
%define _x86_64_lvl 2

# Minimal kernel via modprobed.db (CI only, not for production).
%define _build_minimal 0

%define _build_generic 1
%define _interactive_config 0

# NR_CPUS: 1 = set from _nr_cpus (defaults to nproc), 0 = use kernel default.
%define _set_nr_cpus 0
%define _nr_cpus     %(nproc)

# NVIDIA open kernel modules.
%define _build_nv 1
%define _nv_ver   610.43.02
%define _nv_pkg   open-gpu-kernel-modules-%{_nv_ver}

# ==============================================================================
# Build identification
# ==============================================================================
# _rel:    0 = stable, N = release candidate N
# _koji_patch: 0 = latest available build, N = pin to exact patch number
# _koji_fc:    0 = auto-detect from {dist}, N = override (e.g. 45)

%define _basekver   7.1
%define _stablekver .0
%define _rel        7
%define _koji_patch 47
%define _koji_fc    45

# Build mode:
#   1 = dynamic: fetch Fedora kernel SRPM from Koji at prep time (COPR/local)
#   0 = static:  use a pre-fetched SRPM as Source0 (RPM Fusion / offline builds)
#                requires _koji_patch > 0
%define _koji_dynamic 1

# Release field examples:
#   stable, patch=205  →  205.p03.4.fc44
#   rc4, patch=33      →  33.rc4.p03.4.fc45
#   rc4, auto-patch    →  rc4.p03.4.fc45
%if %{_rel} > 0
  %if %{_koji_patch} > 0
    %define _koji_rel_tag %{_koji_patch}.rc%{_rel}.
  %else
    %define _koji_rel_tag rc%{_rel}.
  %endif
%else
  %if %{_koji_patch} > 0
    %define _koji_rel_tag %{_koji_patch}.
  %else
    %define _koji_rel_tag %{nil}
  %endif
%endif

%if !%{_koji_dynamic}
  %if %{_koji_patch} == 0
    %{error: static mode (_koji_dynamic 0) requires a pinned _koji_patch > 0}
  %endif
  %if %{_rel} > 0
    %define _static_koji_release 0.rc%{_rel}.%{_koji_patch}.fc%{_koji_fc}
  %else
    %define _static_koji_release %{_koji_patch}.fc%{_koji_fc}
  %endif
  %define _static_nvr kernel-%{_tarkver}-%{_static_koji_release}
%endif

%if %{_build_gcc}
    %define _gccreltag .gcc
    %define _gccpacktag -gcc
%endif

# ==============================================================================
# Version strings
# ==============================================================================
%define _tarkver    %{_basekver}%{_stablekver}
%define _custom_tag p03
%define _buildver   1
%define _srcdir     linux-%{_tarkver}
%define _rpmver     %{version}-%{release}
%define _kver       %{_rpmver}.%{_arch}
%define _devel_dir  %{_usrsrc}/kernels/%{_kver}
%define _kernel_dir /lib/modules/%{_kver}

# ==============================================================================
# Validation
# ==============================================================================
%if %{_build_clang} && %{_build_gcc}
  %{error: _build_clang and _build_gcc are mutually exclusive — set only one to 1}
%endif

%if !%{_build_clang} && !%{_build_gcc}
  %{error: no compiler selected — set either _build_clang or _build_gcc to 1}
%endif

%if %{_lto_thin} && %{_lto_full}
  %{error: _lto_thin and _lto_full are mutually exclusive — set only one to 1}
%endif

%if %{_build_gcc} && %{_build_lto}
  %{error: build with gcc does not support lto}
%endif

# ==============================================================================
# Compiler flags
# ==============================================================================
%if %{_opt_level}
  %define _opt_cflags -O%{_opt_level}
%else
  %define _opt_cflags %{nil}
%endif

%if %{_build_clang}
  %define _clang_args  CC=clang CXX=clang++ LD=ld.lld LLVM=1 LLVM_IAS=1
  %define _kcflags     %{_opt_cflags}
  %if %{_opt_level}
    %define _krustflags  -Copt-level=%{_opt_level}
  %else
    %define _krustflags  %{nil}
  %endif
%else
  %if %{_opt_level}
    %define _krustflags  -Copt-level=%{_opt_level}
  %else
    %define _krustflags  %{nil}
  %endif
%endif

%if %{_build_secureboot}
  %define _mok_dir /etc/kernel/certs/p03-kernel
  %define _mok_der %{_mok_dir}/mok.der
  %define _mok_key %{_mok_dir}/mok.key
  %define _mok_pem %{_mok_dir}/mok.pem
%endif

%define _module_args KERNEL_UNAME=%{_kver} IGNORE_PREEMPT_RT_PRESENCE=1 SYSSRC=%{_builddir}/%{_srcdir} SYSOUT=%{_builddir}/%{_srcdir}

# ==============================================================================
# Package metadata
# ==============================================================================
Name:    kernel-%{_custom_tag}%{?_gccpacktag}
Summary: Linux P03
Version: %{_basekver}%{_stablekver}
Release: %{_koji_rel_tag}%{_custom_tag}%{?_gccreltag}.%{_buildver}%{?dist}
License: GPL-2.0-only
URL:     https://github.com/CatPieLeaf/linux-p03

Requires: %{name}-core    = %{_rpmver}
Requires: %{name}-modules = %{_rpmver}

Provides: installonlypkg(kernel)
Provides: kernel-%{_custom_tag}%{?_gccpacktag} > 6.12.9-cb1.0%{?_clang_args:.lto}.%{_custom_tag}%{?dist}

Obsoletes: kernel-%{_custom_tag}%{?_gccpacktag} <= 6.12.9-cb1.0.lto.%{_custom_tag}%{?dist}

# ==============================================================================
# Build dependencies
# ==============================================================================
BuildRequires: bc
BuildRequires: bison
BuildRequires: cpio
BuildRequires: dwarves
BuildRequires: elfutils-devel
BuildRequires: flex
BuildRequires: gcc
BuildRequires: gettext
BuildRequires: kmod
BuildRequires: make
BuildRequires: openssl
BuildRequires: openssl-devel
BuildRequires: perl-Carp
BuildRequires: perl-devel
BuildRequires: perl-generators
BuildRequires: perl-interpreter
BuildRequires: python3-devel
BuildRequires: python3-pyyaml
BuildRequires: zstd
BuildRequires: bindgen
BuildRequires: rust
BuildRequires: rust-src
BuildRequires: rustfmt

%if %{_build_clang}
BuildRequires: clang
BuildRequires: lld
BuildRequires: llvm
BuildRequires: polly
%endif

%if %{_build_nv}
BuildRequires: gcc-c++
%endif

BuildRequires: ncurses-devel
%if %{_interactive_config}
BuildRequires: qt5-qtbase-devel
%endif
%if %{_koji_dynamic}
BuildRequires: koji
%endif
BuildRequires: quilt

# ==============================================================================
# Sources
# ==============================================================================
%if !%{_koji_dynamic}
Source0: https://koji.fedoraproject.org/packages/kernel/%{_tarkver}/%{_static_koji_release}/src/%{_static_nvr}.src.rpm
%endif

Source1: https://raw.githubusercontent.com/CatPieLeaf/linux-p03/refs/heads/main/sources/kconfig/linux-p03.config

%if %{_build_minimal}
Source2: https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux-tkg-config/%{_basekver}/minimal-modprobed.db
%endif

%if %{_build_nv}
Source10: https://github.com/NVIDIA/open-gpu-kernel-modules/archive/%{_nv_ver}/%{_nv_pkg}.tar.gz
%endif

# ==============================================================================
# Patches
# ==============================================================================
%define _cachy_patches https://raw.githubusercontent.com/CachyOS/kernel-patches/master/%{_basekver}
%define _tkg_patches   https://raw.githubusercontent.com/Frogging-Family/linux-tkg/refs/heads/master/linux-tkg-patches/%{_basekver}

%if %{_build_clang}
Patch1: %{_cachy_patches}/misc/0001-clang-polly.patch
Patch2: %{_cachy_patches}/misc/dkms-clang.patch
%endif

Patch3:  %{_cachy_patches}/misc/0001-acpi-call.patch
Patch4:  https://raw.githubusercontent.com/firelzrd/bore-scheduler/refs/heads/main/patches/stable/linux-7.1-bore/0001-linux7.1-rc1-bore-6.6.3.patch
Patch5:  https://raw.githubusercontent.com/firelzrd/adios/refs/heads/main/patches/stable/0001-linux6.19.3-ADIOS-3.2.0.patch
Patch6:  https://raw.githubusercontent.com/CatPieLeaf/linux-p03/refs/heads/main/sources/patches/more-ISA-levels-and-uarches-for-kernel-7.1p.patch
Patch7:  https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0017-cgroup-vram.patch
Patch8:  https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0016-mm-mmput-async.patch
Patch9:  https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0015-mm-libs-grow-down.patch
Patch10: https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0014-sched-ratelimit-yield.patch
Patch11: https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0011-sched-better-idle-balance.patch
Patch12: https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0010-posted-msi-enable-by-default.patch
Patch13: https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0007-tcp-bbr3.patch
Patch14: https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0006-disable-split-lock.patch
Patch15: https://raw.githubusercontent.com/mauri870/linux-kernel/refs/heads/7.1/0004-mm_lazy_rss_stat.patch
Patch16: %{_tkg_patches}/0014-OpenRGB.patch
Patch17: %{_tkg_patches}/0013-optimize_harder_O3.patch
Patch18: %{_tkg_patches}/0012-misc-additions.patch
Patch19: https://raw.githubusercontent.com/firelzrd/poc-selector/refs/heads/main/patches/stable/0001-7.1-rc1-poc-selector-v2.6.2r2.patch
Patch20: %{_tkg_patches}/0003-glitched-base.patch
Patch21: %{_tkg_patches}/0002-clear-patches.patch
Patch22: %{_tkg_patches}/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch
Patch23: https://raw.githubusercontent.com/CatPieLeaf/linux-p03/refs/heads/main/sources/patches/total-misplay.patch
Patch24: https://raw.githubusercontent.com/firelzrd/lru_marie/refs/heads/main/patches/testing/0001-linux7.1-rc5-lru_marie-0.3.1.patch
Patch25: https://raw.githubusercontent.com/CatPieLeaf/linux-p03/refs/heads/main/sources/patches/0003-750hz.patch

# ==============================================================================
%description
    The meta package for %{name}.

# ==============================================================================
%prep
# ==============================================================================
%setup -q %{?SOURCE10:-b 10} -c -T -n %{_srcdir}

%if %{_koji_dynamic}
    # Dynamic mode: resolve and fetch Fedora kernel SRPM from Koji
    _fedoraver=$(echo '%{?dist}' | sed 's/.*\.fc//')
  %if %{_koji_fc} > 0
    _fedoraver="%{_koji_fc}"
  %endif
    [ -z "${_fedoraver}" ] && { echo "ERROR: %{dist} is empty — cannot determine Fedora version" >&2; exit 1; }

  %if %{_rel} > 0
    _pattern="kernel-%{_tarkver}-0.rc%{_rel}.*.fc${_fedoraver}"
  %else
    %if %{_koji_patch} > 0
      _pattern="kernel-%{_tarkver}-%{_koji_patch}.fc${_fedoraver}"
    %else
      _pattern="kernel-%{_tarkver}-*.fc${_fedoraver}"
    %endif
  %endif
    _nvr=$(koji list-builds --package=kernel --state=COMPLETE --pattern="${_pattern}" --quiet \
           | awk '{print $1}' \
           | sort -V | tail -1)
    [ -z "${_nvr}" ] && { echo "ERROR: no Koji build matched: ${_pattern}" >&2; exit 1; }
    _koji_srpm="${_nvr}.src.rpm"

    if [ -f "%{_sourcedir}/${_koji_srpm}" ]; then
        cp "%{_sourcedir}/${_koji_srpm}" "%{_builddir}/${_koji_srpm}"
    else
        cd %{_builddir} && koji download-build --arch=src "${_nvr}"
        cp "%{_builddir}/${_koji_srpm}" "%{_sourcedir}/${_koji_srpm}"
    fi
    _srpm_path="%{_builddir}/${_koji_srpm}"
%else
    # Static mode: use pre-fetched Source0
    _srpm_path="%{SOURCE0}"
%endif

    cd %{_builddir}
    rpm2cpio "${_srpm_path}" | cpio -idm
    _tarball=$(ls linux-*.tar.xz)
    tar xf "${_tarball}" --strip-components=1 -C %{_srcdir}
    cd %{_srcdir}

    cp %{_builddir}/kernel-x86_64-fedora.config .config

%if %{_build_minimal}
    %make_build LSMOD=%{SOURCE2} localmodconfig
%else
    %make_build olddefconfig
%endif

%if %{_interactive_config}
    if [ -t 0 ]; then
        make %{?_clang_args} xconfig
    else
        make %{?_clang_args} nconfig
    fi
%endif

    # Apply patches via quilt. To add a patch: declare PatchN above and
    # append {PATCHN} to the loop below.
    mkdir -p %{_builddir}/patches
    export QUILT_PATCHES=%{_builddir}/patches

%if %{_build_clang}
    for p in %{PATCH1} %{PATCH2}; do
        ln -sf "$p" %{_builddir}/patches/
        echo $(basename "$p") >> %{_builddir}/patches/series
    done
%endif
    for p in \
        %{PATCH3}  %{PATCH4}  %{PATCH5}  %{PATCH6}  %{PATCH7}  \
        %{PATCH8}  %{PATCH9}  %{PATCH10} %{PATCH11} %{PATCH12} \
        %{PATCH13} %{PATCH14} %{PATCH15} %{PATCH16} %{PATCH17} \
        %{PATCH18} %{PATCH19} %{PATCH20} %{PATCH21} %{PATCH22} \
        %{PATCH23} %{PATCH24} %{PATCH25}; do
        ln -sf "$p" %{_builddir}/patches/
        echo $(basename "$p") >> %{_builddir}/patches/series
    done
    quilt push -a --fuzz=2 --leave-rejects

    ./scripts/kconfig/merge_config.sh -m .config %{SOURCE1}

# --- Kconfig -----------------------------------------------------------------

%if %{_build_generic}
    ./scripts/config --enable GENERIC_CPU
%else
    ./scripts/config -u GENERIC_CPU
%endif

    # Tickrate
    case %{_hz_tick} in
    100|250|300|500|600|750|1000)
        ./scripts/config --enable HZ_%{_hz_tick}
        ./scripts/config --set-val HZ %{_hz_tick}
        ;;
    *)
        echo "Invalid tickrate value, using default 1000"
        ./scripts/config --enable HZ_1000
        ./scripts/config --set-val HZ 1000
        ;;
    esac

    # x86_64 ISA level
%if %{_x86_64_lvl} < 5 && %{_x86_64_lvl} > 0
    scripts/config --set-val X86_64_VERSION %{_x86_64_lvl}
%else
    echo "Invalid x86_64 ISA Level. Using x86_64_v3"
    scripts/config --set-val X86_64_VERSION 3
%endif

    # Secure Boot: IMA, module signing, lockdown
%if %{_build_secureboot}
    scripts/config -e  CONFIG_IMA
    scripts/config -e  CONFIG_IMA_APPRAISE
    scripts/config -e  CONFIG_IMA_APPRAISE_BOOTPARAM
    scripts/config -e  CONFIG_IMA_APPRAISE_MODSIG
    scripts/config -e  CONFIG_IMA_ARCH_POLICY
    scripts/config -e  CONFIG_IMA_SECURE_AND_OR_TRUSTED_BOOT
    scripts/config -d  CONFIG_IMA_DEFAULT_HASH_SHA1
    scripts/config -e  CONFIG_IMA_DEFAULT_HASH_SHA256
    scripts/config --set-str CONFIG_IMA_DEFAULT_HASH "sha256"
    scripts/config -e  MODULE_SIG
    scripts/config -e  MODULE_SIG_ALL
    scripts/config -e  MODULE_SIG_FORCE
    scripts/config -e  MODULE_SIG_SHA512
    scripts/config --set-str MODULE_SIG_HASH sha512
    scripts/config -e  CONFIG_KEXEC_SIG
    scripts/config -e  INTEGRITY_ASYMMETRIC_KEYS
    scripts/config -e  INTEGRITY_SIGNATURE
    scripts/config -e  LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY
    scripts/config -e  SECURITY_LOCKDOWN_LSM
    scripts/config -e  SECURITY_LOCKDOWN_LSM_EARLY
    scripts/config -e  SYSTEM_EXTRA_CERTIFICATE
    scripts/config --set-val SYSTEM_EXTRA_CERTIFICATE_SIZE 4096
    scripts/config -e  SYSTEM_TRUSTED_KEYRING
%endif

    # Clang LTO
%if %{_build_clang} && %{_build_lto}
    scripts/config -d CONFIG_LTO_NONE
    scripts/config -e POLLY_CLANG  # requires clang-polly patch (Patch1)
  %if %{_lto_thin}
    scripts/config -e  CONFIG_LTO_CLANG_THIN
    scripts/config -e  LTO_CLANG_THIN
    scripts/config -d  CONFIG_LTO_CLANG_FULL
    scripts/config -d  LTO_CLANG_FULL
  %endif
  %if %{_lto_full}
    scripts/config -e  CONFIG_LTO_CLANG_FULL
    scripts/config -e  LTO_CLANG_FULL
    scripts/config -d  CONFIG_LTO_CLANG_THIN
    scripts/config -d  LTO_CLANG_THIN
  %endif
%endif

    # Optimization level
%if %{_opt_level} == 3
    scripts/config -d CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
    scripts/config -e CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3
    scripts/config -d CONFIG_CC_OPTIMIZE_FOR_SIZE
%else
  %if %{_opt_level} == 2
    scripts/config -e CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
    scripts/config -d CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3
    scripts/config -d CONFIG_CC_OPTIMIZE_FOR_SIZE
  %else
    %if %{_opt_level} == 0
      scripts/config -d CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
      scripts/config -d CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3
      scripts/config -e CONFIG_CC_OPTIMIZE_FOR_SIZE
    %endif
  %endif
%endif

    scripts/config -e ZENIFY

%if %{_set_nr_cpus}
    scripts/config -d CPUMASK_OFFSTACK
    scripts/config -d MAXSMP
    scripts/config --set-val NR_CPUS %{_nr_cpus}
%endif

    # Debug info
%if %{_build_debug}
    scripts/config -d CONFIG_DEBUG_INFO_NONE
    scripts/config -e CONFIG_DEBUG_INFO
    scripts/config -e CONFIG_DEBUG_INFO_DWARF5
    scripts/config -e CONFIG_DEBUG_INFO_BTF
%endif

    %make_build oldconfig

%if %{_build_minimal}
    %make_build LSMOD=%{SOURCE2} localmodconfig
%else
    %make_build olddefconfig
%endif

    diff -u %{SOURCE1} .config || :

# ==============================================================================
%build
# ==============================================================================
    %make_build EXTRAVERSION=-%{release}.%{_arch} KCFLAGS="%{?_kcflags}" KRUSTFLAGS="%{?_krustflags}" all

    # bpftool vmlinux.h for the devel package
    %make_build -C tools/bpf/bpftool vmlinux.h feature-clang-bpf-co-re=1 || true

%if %{_build_nv}
    cd %{_builddir}/%{_nv_pkg}
    CFLAGS= CXXFLAGS= LDFLAGS= %make_build %{?_clang_args} %{_module_args} IGNORE_CC_MISMATCH=yes modules
%endif

# ==============================================================================
%install
# ==============================================================================

    # 1. Kernel modules
    echo "Installing kernel modules..."
    ZSTD_CLEVEL=19 %make_build INSTALL_MOD_PATH="%{buildroot}" INSTALL_MOD_STRIP=1 DEPMOD=/doesnt/exist modules_install

    # 2. NVIDIA modules
%if %{_build_nv}
    echo "Installing NVIDIA modules..."
    cd %{_builddir}/%{_nv_pkg}
    install -Dt %{buildroot}%{_kernel_dir}/nvidia -m644 kernel-open/*.ko
    find %{buildroot}%{_kernel_dir}/nvidia -name '*.ko' -exec zstd -19 --rm {} \;
    install -Dt %{buildroot}/%{_defaultlicensedir}/%{name}-nvidia-open -m644 COPYING
    cd %{_builddir}/%{_srcdir}
%endif

    # 3. Kernel image — signing deferred to posttrans on the target machine;
    #    the build host must never hold the private MOK key.
    echo "Installing kernel image..."
    install -Dm644 "$(%make_build -s image_name)" "%{buildroot}%{_kernel_dir}/vmlinuz"

%if %{_build_secureboot}
    # ship sign-file so posttrans can sign external modules without -devel
    install -Dm755 scripts/sign-file "%{buildroot}%{_kernel_dir}/sign-file"
%endif

    # 4. Development files
    zstdmt -19 < Module.symvers > %{buildroot}%{_kernel_dir}/symvers.zst

    install -Dt %{buildroot}%{_devel_dir} -m644 .config Makefile Module.symvers System.map
    [ -f tools/bpf/bpftool/vmlinux.h ] && install -m644 tools/bpf/bpftool/vmlinux.h %{buildroot}%{_devel_dir}/ || true
    cp .config    %{buildroot}%{_kernel_dir}/config
    cp System.map %{buildroot}%{_kernel_dir}/System.map

    cp --parents `find -type f -name "Makefile*" -o -name "Kconfig*"` %{buildroot}%{_devel_dir}
    cp -a scripts %{buildroot}%{_devel_dir}
    rm -rf %{buildroot}%{_devel_dir}/include
    rm -rf %{buildroot}%{_devel_dir}/scripts
    rm -rf %{buildroot}%{_devel_dir}/scripts/tracing
    rm -f  %{buildroot}%{_devel_dir}/scripts/spdxcheck.py

    # Files needed for `make scripts`
    cp -a --parents security/selinux/include/classmap.h              %{buildroot}%{_devel_dir}
    cp -a --parents security/selinux/include/initial_sid_to_string.h %{buildroot}%{_devel_dir}
    cp    --parents security/selinux/include/policycap.h             %{buildroot}%{_devel_dir}
    cp    --parents security/selinux/include/policycap_names.h       %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/tools/be_byteshift.h               %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/tools/le_byteshift.h               %{buildroot}%{_devel_dir}

    # Files needed for `make prepare` — generic
    cp -a --parents tools/bpf/resolve_btfids          %{buildroot}%{_devel_dir}
    cp -a --parents tools/build/Build.include         %{buildroot}%{_devel_dir}
    cp    --parents tools/build/fixdep.c              %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/asm                 %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/asm-generic         %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/linux               %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/linux/compiler*     %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/linux/types.h       %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/uapi/asm            %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/uapi/asm-generic    %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/uapi/linux          %{buildroot}%{_devel_dir}
    cp -a --parents tools/include/vdso                %{buildroot}%{_devel_dir}
    cp -a --parents tools/lib/bpf                     %{buildroot}%{_devel_dir}
    cp    --parents tools/lib/bpf/Build               %{buildroot}%{_devel_dir}
    cp    --parents tools/lib/*.c                     %{buildroot}%{_devel_dir}
    cp -a --parents tools/lib/subcmd                  %{buildroot}%{_devel_dir}
    cp    --parents tools/objtool/*.[ch]              %{buildroot}%{_devel_dir}
    cp    --parents tools/objtool/Build               %{buildroot}%{_devel_dir}
    cp    --parents tools/objtool/include/objtool/*.h %{buildroot}%{_devel_dir}
    cp    --parents tools/objtool/sync-check.sh       %{buildroot}%{_devel_dir}
    cp    --parents tools/scripts/utilities.mak       %{buildroot}%{_devel_dir}

    # Files needed for `make prepare` — x86_64
    cp -a --parents arch/x86/boot/ctype.h                    %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/boot/string.c                   %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/boot/string.h                   %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/entry/syscalls/syscall_32.tbl   %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/entry/syscalls/syscall_64.tbl   %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/include                         %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/purgatory/entry64.S             %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/purgatory/purgatory.c           %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/purgatory/setup-x86_64.S        %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/purgatory/stack.S               %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/tools/relocs.c                  %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/tools/relocs.h                  %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/tools/relocs_32.c               %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/tools/relocs_64.c               %{buildroot}%{_devel_dir}
    cp -a --parents arch/x86/tools/relocs_common.c           %{buildroot}%{_devel_dir}
    cp -a --parents scripts/syscallhdr.sh                    %{buildroot}%{_devel_dir}
    cp -a --parents scripts/syscalltbl.sh                    %{buildroot}%{_devel_dir}
    cp -a --parents tools/arch/x86/include/asm               %{buildroot}%{_devel_dir}
    cp -a --parents tools/arch/x86/include/uapi/asm          %{buildroot}%{_devel_dir}
    cp -a --parents tools/arch/x86/lib/                      %{buildroot}%{_devel_dir}
    cp -a --parents tools/arch/x86/tools/gen-insn-attr-x86.awk %{buildroot}%{_devel_dir}
    cp -a --parents tools/objtool/arch/x86/                  %{buildroot}%{_devel_dir}

    cp -a include                    %{buildroot}%{_devel_dir}/include
    cp -a sound/soc/sof/sof-audio.h %{buildroot}%{_devel_dir}/sound/soc/sof
    cp -a tools/objtool/fixdep       %{buildroot}%{_devel_dir}/tools/objtool/
    cp -a tools/objtool/objtool      %{buildroot}%{_devel_dir}/tools/objtool/

    echo "Cleaning up development files..."
    find %{buildroot}%{_devel_dir}/scripts \( -iname "*.o" -o -iname "*.cmd" \) -exec rm -f {} +
    find %{buildroot}%{_devel_dir}/tools   \( -iname "*.o" -o -iname "*.cmd" \) -exec rm -f {} +
    touch -r %{buildroot}%{_devel_dir}/Makefile %{buildroot}%{_devel_dir}/include/generated/uapi/linux/version.h %{buildroot}%{_devel_dir}/include/config/auto.conf

    # These symlinks are owned by the modules package; they would be broken
    # without the -devel package installed.
    rm -rf %{buildroot}%{_kernel_dir}/build
    ln -s %{_devel_dir}        %{buildroot}%{_kernel_dir}/build
    ln -s %{_kernel_dir}/build %{buildroot}%{_kernel_dir}/source

    # Stub initramfs to prevent failures due to insufficient space in /boot (bz #530778)
    install -dm755 %{buildroot}/boot
    dd if=/dev/zero of=%{buildroot}/boot/initramfs-%{_kver}.img bs=1M count=90

# ==============================================================================
%package core
# ==============================================================================
Summary: Linux P03
AutoReq: no

Conflicts: xfsprogs < 4.3.0-1
Conflicts: xorg-x11-drv-vmmouse < 13.0.99

Provides: installonlypkg(kernel)
Provides: kernel              = %{_rpmver}
Provides: kernel-core-uname-r = %{_kver}
Provides: kernel-uname-r      = %{_kver}

Requires:      kernel-modules-uname-r = %{_kver}
Requires(pre): /usr/bin/kernel-install
Requires(pre): coreutils
Requires(pre): dracut >= 027
Requires(pre): systemd >= 203-2
Requires(pre): ((linux-firmware >= 20150904-56.git6ebf5d57) if linux-firmware)

Requires(preun): systemd >= 200

Recommends: linux-firmware

%if %{_build_secureboot}
Requires(post): openssl
Requires(post): nss-tools
Requires(post): pesign
%endif

%description core
    The kernel package contains the Linux kernel (vmlinuz), the core of any
    Linux operating system. The kernel handles the basic functions of the
    operating system: memory allocation, process allocation, device input
    and output, etc.

%post core
    mkdir -p %{_localstatedir}/lib/rpm-state/%{name}
    touch %{_localstatedir}/lib/rpm-state/%{name}/installing_core_%{_kver}

%posttrans core
    rm -f %{_localstatedir}/lib/rpm-state/%{name}/installing_core_%{_kver}
%if %{_build_secureboot}
    # MOK key generation and vmlinuz signing — runs on the TARGET machine.
    # The private key is never present on the build host; generated here once
    # and reused across upgrades that share the same enrolled MOK certificate.
    MOK_CN="P03 Kernel Secure Boot"
    MOK_DIR="%{_mok_dir}"
    MOK_KEY="%{_mok_key}"
    MOK_DER="%{_mok_der}"
    MOK_PEM="%{_mok_pem}"

    mkdir -p "${MOK_DIR}"
    chmod 700 "${MOK_DIR}"

    if [ ! -f "${MOK_KEY}" ]; then
        echo "Generating MOK key at ${MOK_DIR} ..."
        openssl req -new -x509 -newkey rsa:4096 -keyout "${MOK_KEY}" -outform DER -out "${MOK_DER}" -nodes -days 36500 -subj "/CN=${MOK_CN}/" -addext "extendedKeyUsage=codeSigning"
        chmod 600 "${MOK_KEY}"
        openssl x509 -inform DER -in "${MOK_DER}" -out "${MOK_PEM}"
        echo "MOK key generated."
    else
        echo "Reusing existing MOK key from ${MOK_DIR}."
    fi

    # Sign vmlinuz in-place BEFORE kernel-install copies it to /boot
    # so the file that ends up in /boot is already signed.
    echo "Signing vmlinuz for Secure Boot..."
    SB_VMLINUZ="%{_kernel_dir}/vmlinuz"
    TMP_NSS=$(mktemp -d)
    trap "rm -rf ${TMP_NSS}" EXIT
    certutil  -d "${TMP_NSS}" -N --empty-password
    openssl pkcs12 -export -out "${TMP_NSS}/sb.p12" -inkey "${MOK_KEY}" -in "${MOK_PEM}" -name "${MOK_CN}" -passout pass:
    pk12util -i "${TMP_NSS}/sb.p12" -d "${TMP_NSS}" -W ""
    pesign -n "${TMP_NSS}" -c "${MOK_CN}" --sign -i "${SB_VMLINUZ}" -o "${SB_VMLINUZ}.signed"
    mv "${SB_VMLINUZ}.signed" "${SB_VMLINUZ}"
    trap - EXIT
    rm -rf "${TMP_NSS}"
    echo "vmlinuz signed."
%endif
    if [ ! -e /run/ostree-booted ]; then
        /bin/kernel-install add %{_kver} %{_kernel_dir}/vmlinuz || exit $?
        if [[ ! -e "/boot/symvers-%{_kver}.zst" ]]; then
            cp "%{_kernel_dir}/symvers.zst" "/boot/symvers-%{_kver}.zst"
            if command -v restorecon &>/dev/null; then
                restorecon "/boot/symvers-%{_kver}.zst"
            fi
        fi
    fi
%if %{_build_secureboot}
    if command -v mokutil &>/dev/null; then
        SB_STATE=$(mokutil --sb-state 2>/dev/null || true)
        echo ""
        echo "======================================================================"
        echo " Kernel P03: Secure Boot key enrollment"
        echo "======================================================================"
        echo " MOK key: %{_mok_der}"
        echo " Current Secure Boot state: ${SB_STATE:-unknown}"
        echo " To enroll the key (only needed once per machine), run:"
        echo "   sudo mokutil --import %{_mok_der}"
        echo " Then reboot and confirm enrollment in the MOK Manager (shim)."
        echo "======================================================================"
    fi
%endif

%preun core
    /bin/kernel-install remove %{_kver} || exit $?
    if [ -x /usr/sbin/weak-modules ]; then
        /usr/sbin/weak-modules --remove-kernel %{_kver} || exit $?
    fi

%files core
    %license COPYING
    %ghost %attr(0600, root, root) /boot/initramfs-%{_kver}.img
    %ghost %attr(0644, root, root) /boot/symvers-%{_kver}.zst
%if %{_build_secureboot}
    # ghost: generated on the target machine by posttrans; tracked for removal
    # but not present in the RPM payload itself.
    %ghost %attr(0700, root, root) %dir %{_mok_dir}
    %ghost %attr(0600, root, root) %{_mok_key}
    %ghost %attr(0644, root, root) %{_mok_der}
    %ghost %attr(0644, root, root) %{_mok_pem}
    %{_kernel_dir}/sign-file
%endif
    %{_kernel_dir}/System.map
    %{_kernel_dir}/config
    %{_kernel_dir}/modules.builtin
    %{_kernel_dir}/modules.builtin.modinfo
    %{_kernel_dir}/symvers.zst
    %{_kernel_dir}/vmlinuz

# ==============================================================================
%package modules
# ==============================================================================
Summary: Kernel modules for %{name}

Provides: installonlypkg(kernel-module)
Provides: kernel-modules              = %{_rpmver}
Provides: kernel-modules-core         = %{_rpmver}
Provides: kernel-modules-core-uname-r = %{_kver}
Provides: kernel-modules-extra        = %{_rpmver}
Provides: kernel-modules-extra-uname-r = %{_kver}
Provides: kernel-modules-uname-r      = %{_kver}
Provides: v4l2loopback-kmod           = 0.14.0

Requires: kernel-uname-r = %{_kver}
Requires: kmod

%description modules
    This package provides kernel modules for the %{name}-core kernel package.

%post modules
    if [ ! -f %{_localstatedir}/lib/rpm-state/%{name}/installing_core_%{_kver} ]; then
        mkdir -p %{_localstatedir}/lib/rpm-state/%{name}
        touch %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver}
    fi

%posttrans modules
    /sbin/depmod -a %{_kver}
    if [ ! -e /run/ostree-booted ]; then
        if [ -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver} ]; then
            rm -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver}
            echo "Running: dracut -f --kver %{_kver}"
            dracut -f --kver "%{_kver}" || exit $?
        fi
    fi
    rm -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver}

%files modules
    %dir %{_kernel_dir}
    %{_kernel_dir}/build
    %{_kernel_dir}/kernel
    %{_kernel_dir}/modules.order
    %{_kernel_dir}/source

# ==============================================================================
%package devel
# ==============================================================================
Summary:     Development package for building kernel modules against %{name}
AutoReqProv: no

Provides: installonlypkg(kernel)
Provides: kernel-devel         = %{_rpmver}
Provides: kernel-devel-uname-r = %{_kver}

Requires: bison
Requires: elfutils-libelf-devel
Requires: findutils
Requires: flex
Requires: make
Requires: openssl-devel
Requires: perl-interpreter

%if %{_build_clang}
Requires: clang
Requires: lld
Requires: llvm
%else
Requires: gcc
%endif

%description devel
    This package provides kernel headers and makefiles sufficient to build
    modules against %{name}.

%post devel
    if [ -f /etc/sysconfig/kernel ]; then
        . /etc/sysconfig/kernel || exit $?
    fi
    if [ "$HARDLINK" != "no" -a -x /usr/bin/hardlink -a ! -e /run/ostree-booted ]; then
        (cd /usr/src/kernels/%{_kver} &&
        /usr/bin/find . -type f | while read f; do
            hardlink -c /usr/src/kernels/*%{?dist}.*/$f $f > /dev/null
        done;
        )
    fi

%files devel
    %{_devel_dir}

# ==============================================================================
%package devel-matched
# ==============================================================================
Summary: Meta package to install matching core, modules and devel for %{name}

Provides: installonlypkg(kernel)
Provides: kernel-devel-matched = %{_rpmver}

Requires: %{name}-core    = %{_rpmver}
Requires: %{name}-modules = %{_rpmver}
Requires: %{name}-devel   = %{_rpmver}

%description devel-matched
    This meta package pulls in kernel-p03-core, kernel-p03-modules and
    kernel-p03-devel together.

%files devel-matched

# ==============================================================================
%if %{_build_nv}
%package nvidia-open
# ==============================================================================
Summary: nvidia-open %{_nv_ver} kernel modules for %{name}
License: MIT AND GPL-2.0-only

Provides: installonlypkg(kernel-module)
Provides: nvidia-kmod >= %{_nv_ver}

Requires: kernel-uname-r = %{_kver}
Requires: kmod
Requires: nvidia-gpu-firmware
%if %{_build_secureboot}
Requires: zstd
%endif

Conflicts: akmod-nvidia

%description nvidia-open
    This package provides nvidia-open %{_nv_ver} kernel modules for %{name}.

%post nvidia-open
    _NV_URL="https://download.nvidia.com/XFree86/Linux-x86_64/%{_nv_ver}/NVIDIA-Linux-x86_64-%{_nv_ver}.run"
    echo ""
    echo "======================================================================"
    echo " !!!   NVIDIA USERSPACE DRIVER REQUIRED   !!!"
    echo "======================================================================"
    echo " This package ships ONLY the open kernel modules."
    echo " You MUST install the matching NVIDIA userspace driver (%{_nv_ver})"
    echo " separately."
    echo " "
    echo " DO NOT use dnf/rpm to install nvidia drivers — they will pull in"
    echo " conflicting kernel modules."
    echo " Use the official .run installer with the flags below."
    echo " "
    echo " Download:"
    echo "   wget ${_NV_URL}"
    echo " "
    echo " Install:"
    echo "   sudo sh ./NVIDIA-Linux-x86_64-${_nv_ver}.run --no-kernel-modules --no-dkms --no-nouveau-check"
    echo " "
    echo "======================================================================"

    /sbin/depmod -a %{_kver}
    mkdir -p %{_localstatedir}/lib/rpm-state/%{name}
    touch %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver}

%posttrans nvidia-open
%if %{_build_secureboot}
    # Sign NVIDIA modules on the target machine using the MOK key from posttrans core.
    MOK_KEY="%{_mok_key}"
    MOK_PEM="%{_mok_pem}"
    SIGN_FILE="%{_kernel_dir}/sign-file"

    if [ -f "${MOK_KEY}" ] && [ -x "${SIGN_FILE}" ]; then
        echo "Signing NVIDIA modules for Secure Boot..."
        while IFS= read -r KO; do
            UNZST="${KO%.zst}"
            if ! zstd -d --rm "${KO}" -o "${UNZST}"; then
                echo "ERROR: failed to decompress ${KO}" >&2; exit 1
            fi
            if ! "${SIGN_FILE}" sha512 "${MOK_KEY}" "${MOK_PEM}" "${UNZST}"; then
                echo "ERROR: failed to sign ${UNZST}" >&2; exit 1
            fi
            if ! zstd -19 --rm "${UNZST}" -o "${KO}"; then
                echo "ERROR: failed to recompress ${UNZST}" >&2; exit 1
            fi
        done < <(find "%{_kernel_dir}/nvidia" -name "*.ko.zst")
        echo "NVIDIA modules signed."
    else
        echo "WARNING: MOK key not found at ${MOK_KEY}."
        echo "         Install or reinstall %{name}-core first so the key is"
        echo "         generated, then reinstall %{name}-nvidia-open."
    fi
%endif
    /sbin/depmod -a %{_kver}
    if [ -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver} ]; then
        rm -f %{_localstatedir}/lib/rpm-state/%{name}/need_to_run_dracut_%{_kver}
        echo "Running: dracut -f --kver %{_kver}"
        dracut -f --kver "%{_kver}" || exit $?
    fi

%files nvidia-open
    %license %{_defaultlicensedir}/%{name}-nvidia-open/COPYING
    %{_kernel_dir}/nvidia
%endif

# ==============================================================================
%files
