function Fast_set_cvmfs_vars(){
    Fast_cvmfs_PythonDir=/cvmfs/sft.cern.ch/lcg/releases/Python/2.7.13-597a5/x86_64-slc6-gcc62-opt/
    Fast_cvmfs_PipDir=/cvmfs/sft.cern.ch/lcg/releases/pip/8.1.2-c9f5a/x86_64-slc6-gcc62-opt/
    Fast_cvmfs_GCCSetup=/cvmfs/sft.cern.ch/lcg/contrib/gcc/6.2/x86_64-slc6/setup.sh
    Fast_cvmfs_RootSetup=/cvmfs/sft.cern.ch/lcg/releases/LCG_88/ROOT/6.08.06/x86_64-slc6-gcc62-opt/bin/thisroot.sh
    Fast_cvmfs_Libs=/cvmfs/sft.cern.ch/lcg/views/LCG_88/x86_64-slc6-gcc62-opt/
    Fast_cvmfs_LzmaDir=/cvmfs/cms.cern.ch/slc6_amd64_gcc620/external/xz/5.2.2/
}
export -f Fast_set_cvmfs_vars
Fast_set_cvmfs_vars

if [ -z "$(which root-config 2>/dev/null)" ] \
    || [[ "$(root-config --version)" != 6.* ]] ;then
    if [ -r "${Fast_cvmfs_RootSetup}" ] && [ -r "$Fast_cvmfs_GCCSetup" ]; then
      source "${Fast_cvmfs_GCCSetup}"
      source "${Fast_cvmfs_RootSetup}"
    else
      echo "Cannot setup ROOT 6 and it doesn't seem to be configured already, this might be an issue..."
    fi
fi

FAST_top_dir(){
  local Canonicalize="readlink -f"
  $Canonicalize asdf &> /dev/null || Canonicalize=realpath
  dirname "$($Canonicalize "${BASH_SOURCE[0]}")"
}

export FAST_RA1_ROOT="$(FAST_top_dir)"
export FAST_RA1_EXTERNALS_DIR="$(FAST_top_dir)/external"
export FAST_RA1_HAVE_ALPHATOOLS="$([ -r "$FAST_RA1_EXTERNALS_DIR/AlphaTools" ] && echo true || echo false)"

FAST_build_some_path(){
  local NewPath="$1" ;shift
  for dir in "$@";do
    if ! $( echo "$NewPath" | grep -q '\(.*:\|^\)'"$dir"'\(:.*\|$\)' ); then
      NewPath="${dir}${NewPath:+:${NewPath}}"
    fi
  done
  echo "$NewPath"
}

FAST_build_path(){
  local Dirs=( "${FAST_RA1_ROOT}"/bin "${FAST_RA1_EXTERNALS_DIR}"/pip/bin "${FAST_RA1_ROOT}"/external/cms-das-query/bin/ )
  Dirs+=( {"$Fast_cvmfs_PythonDir","$Fast_cvmfs_PipDir"}/bin)
  FAST_build_some_path "$PATH" "${Dirs[@]}"
}

FAST_build_python_path(){
  local Dirs=( "${FAST_RA1_ROOT}" "${FAST_RA1_EXTERNALS_DIR}"/{alphatwirl,alphatwirl-interface,aggregate,cms-das-query,pip/lib/python2.7/site-packages} )
  if "$FAST_RA1_HAVE_ALPHATOOLS"; then
    Dirs+=("${FAST_RA1_EXTERNALS_DIR}"/AlphaTools/analysis/{,Core,Configuration})
  fi
  Dirs+=( {"$Fast_cvmfs_PythonDir","$Fast_cvmfs_PipDir"}/lib/python2.7/site-packages/)

  FAST_build_some_path "$PYTHONPATH" "${Dirs[@]}"
}

export PYTHONPATH="$(FAST_build_python_path)"
export PATH="$(FAST_build_path)"
export LD_LIBRARY_PATH="$(FAST_build_some_path "$LD_LIBRARY_PATH" "${Fast_cvmfs_Libs}"{lib,lib64} "${Fast_cvmfs_LzmaDir}"/lib )"

if "$FAST_RA1_HAVE_ALPHATOOLS";then
  export ALPHATOOLSDIR="${FAST_RA1_EXTERNALS_DIR}/AlphaTools/analysis"
fi

PS1_PREFIX=FAST-RA1

unset FAST_build_some_path
unset FAST_build_path
unset FAST_build_python_path
unset ${!Fast_cvmfs_*}
