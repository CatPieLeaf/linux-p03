
<div align="center">
  <img src=".github/card.png" width="200"></img>
  <br/>
</div>

---

<div align="center">
  <img src=".github/title-darkmode.png#gh-dark-mode-only" width="450">
  <img src=".github/title-lightmode.png#gh-light-mode-only" width="450">
  <p align="center">A zero-misplay kernel with CachyOS, TKG, Clear Linux patches and more, built from Fedora Koji SRPMs.</p>
</div>

<p align="center">This repository provides a set of tools to automatically build patch and compile the Linux Kernel from Fedora Koji SPRMs, with a selection of patches and configurations aiming for a better system responsiveness.</p>

---

<div align="center">
  <img src=".github/floppy.png" width="80"></img>
  <h4>F E A T U R E S</h4>
</div>

 - Built on top of Fedora Koji Sources with Fedora's baseconfigs
 - Automatic Secureboot Signing (For nvidia drivers too!)
 - NVIDIA-Open Kernel Modules support
 - ThinLTO or FullLTO (Copr builds are ThinLTO)
 - Per-CPU ISA Optimizations (Copr only provides Generic x86-64v3)
 - 1000hz tickrate
 - Built with LLVM + O3 + Polly Clang
 - BORE scheduler
 - BBRv3 congestion control and FQ qdisk
 - OpenRGB Support
 - xConfig and nConfig during build
 - ADIOS I/O Scheduler
 - Piece-Of-Cake (POC) CPU Selector
 - Dynamic PREEMPT (Lazy by default)
 - Passive intel_pstate
 - Catastrophic Misplay Screen: A custom P03-themed QR-Code panic screen for those rare, fatal errors.

<p align="center">For nvidia, install using the command below, since kernel modules are already installed.</p>

```
sudo sh ./Nvidia.run --no-kernel-modules --no-dkms --no-nouveau-check
```

<p align="center">Tip: build the whole kernel in your RAM to save SSD health with the command below (10gb ram required)</p>

```
sudo mount -t tmpfs -o size=10G tmpfs ~/rpmbuild/BUILD
```



<div align="center">
  <h1>📑</h1>
  <h4>C R E D I T S</h4>
</div>

 - P03 and Inscryption are property of Daniel Mullins Games and Devolver Digital. This kernel is a non-commercial fan project and not affiliated with or endorsed by the original creators.
 - Patches and configuration files from [Linux-TKG](https://github.com/Frogging-Family/linux-tkg)
 - Patches from [Mauri870's Custom Kernel](https://github.com/mauri870/linux-kernel/)
 - Patches from [CachyOS Kernel](https://github.com/CachyOS/kernel-patches/)
 - Bore patches from [Firelzrd](https://github.com/firelzrd/bore-scheduler)
 - ADIOS patches from [Firelzrd](https://github.com/firelzrd/adios)
 - POC patches from [Firelzrd](https://github.com/firelzrd/poc-selector)
 - Kcompress-Unofficial patches from [Firelzrd](https://github.com/firelzrd/kcompressd-unofficial)
 - Le9uo patches from [Firelzrd](https://github.com/firelzrd/le9uo)
 - Based on the specfile from [CachyOS for Fedora COPR](https://github.com/CachyOS/copr-linux-cachyos)

---

<div align="center">
  <img src=".github/stoat-darkmode.png#gh-dark-mode-only" width="400">
  <img src=".github/stoat-lightmode.png#gh-light-mode-only" width="400">
</div>
