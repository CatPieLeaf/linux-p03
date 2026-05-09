
<div align="center">
  <img src=".github/card.png" width="200"></img>
  <br/>
  <h1 align="center">P03 Kernel for Fedora</h1>
    <p align="center">A zero-misplay kernel with CachyOS, TKG, Clear Linux patches and more, built from Fedora Koji SRPMs.</p>
</div>

## 💾 About

This repository provides a set of tools to automatically build patch and compile the Linux Kernel from Fedora Koji SPRMs, with a selection of patches and configurations aiming for a better system responsiveness.

<h1 align="center">⚠️</h1>
<h4 align="center">Thar will be dragons!</h4>

This project is a work-in-progress and primarily intended for personal use. While a COPR repository is mentioned in the code, it does not exist yet. It may contain many configurations specifically made for my own setup (-march alderlake, ASUS WMI, etc).

If you build the kernel in this WIP state, without removing these specific tweaks, you MIGHT end up on a Misplay screen.

## ✨ Features

 - Built on top of Fedora Koji Sources
 - Automatic Secureboot Signing (For nvidia drivers too!)
 - NVIDIA-Open Kernel Modules support
 - ThinLTO or FullLTO (Copr builds are ThinLTO)
 - Per-CPU ISA Optimizations (Copr only provides Generic x86-64v3 and x86-64v2)
 - 1000hz tickrate
 - Built with LLVM + O3 + Polly Clang
 - BORE scheduler
 - BBRv3 congestion control and CAKE queue management for the sake of bufferbloat
 - OpenRGB Support
 - xConfig and nConfig during build
 - ADIOS I/O Scheduler
 - Dynamic PREEMPT (Lazy by default)
 - Passive intel_pstate
 - Catastrophic Misplay Screen: A custom P03-themed QR-Code panic screen for those rare, fatal errors.

For nvidia, install using `sudo sh ./Nvidia.run --no-kernel-modules --no-dkms --no-nouveau-check`, since kernel modules are already installed.


### 📑 Credits
 - P03 and Inscryption are property of Daniel Mullins Games and Devolver Digital. This kernel is a non-commercial fan project and not affiliated with or endorsed by the original creators.
 - Patches and configuration files from [Linux-TKG](https://github.com/Frogging-Family/linux-tkg)
 - Patches from [Mauri870's Custom Kernel](https://github.com/mauri870/linux-kernel/)
 - Patches from [CachyOS Kernel](https://github.com/CachyOS/kernel-patches/)
 - Bore patches from [Firelzrd](https://github.com/firelzrd/bore-scheduler)
 - ADIOS patches from [Firelzrd](https://github.com/firelzrd/adios)
 - Based on the specfile from [CachyOS for Fedora COPR](https://github.com/CachyOS/copr-linux-cachyos)
