%global _p03_tmpspec %(mktemp /tmp/kernel-p03-deck-XXXXXX.spec)
%global _p03_fetch_ok %(curl -fsSL -o %{_p03_tmpspec} https://raw.githubusercontent.com/CatPieLeaf/linux-p03/main/sources/kernel-p03/kernel-p03.spec && echo 1 || echo 0)
%if %{_p03_fetch_ok} == 0
  %{error: failed to fetch main specfile (sources/kernel-p03/kernel-p03.spec) from GitHub}
%endif

%global _with_handheld 1
%include %{_p03_tmpspec}
