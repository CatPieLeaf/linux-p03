%global _p03_tmpspec %(mktemp /tmp/kernel-p03-raku-XXXXXX.spec)
%global _p03_fetch_ok %(curl -fsSL -o %{_p03_tmpspec} https://raw.githubusercontent.com/CatPieLeaf/linux-p03/raku/sources/kernel-p03/kernel-p03-raku.spec && echo 1 || echo 0)
%if %{_p03_fetch_ok} == 0
  %{error: failed to fetch raku specfile (sources/kernel-p03/kernel-p03-raku.spec) from GitHub}
%endif

%global _with_gcc 1
%global _x86_64_lvl 2
%include %{_p03_tmpspec}
