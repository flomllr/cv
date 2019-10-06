#!/usr/bin/env bash

set -o errexit

# We use $DEPLOY_URL to detect the Netlify environment.
if [ -v DEPLOY_URL ]; then
  : ${NETLIFY_BUILD_BASE="/opt/buildhome"}
else
  : ${NETLIFY_BUILD_BASE="$PWD/buildhome"}
fi

NETLIFY_CACHE_DIR="$NETLIFY_BUILD_BASE/cache"

TEXLIVE_DIR="$NETLIFY_CACHE_DIR/texlive"
TEXLIVE_BIN="$TEXLIVE_DIR/2018/bin/x86_64-linux"

INSTALL_TL="install-tl-unx.tar.gz"
INSTALL_TL_VERSION="$(tar tf "$INSTALL_TL" | grep -om1 '^install-tl-[0-9]*')"
INSTALL_TL_SUCCESS="$NETLIFY_CACHE_DIR/$INSTALL_TL_VERSION-success"

TEXLIVEONFLY="$TEXLIVE_DIR/2018/texmf-dist/scripts/texliveonfly/texliveonfly.py"

TEXLIVE_PROFILE="\
selected_scheme scheme-custom
TEXMFCONFIG \$TEXMFSYSCONFIG
TEXMFHOME \$TEXMFLOCAL
TEXMFVAR \$TEXMFSYSVAR
binary_x86_64-linux 1
collection-basic 1
collection-binextra 1
collection-latex 1
instopt_adjustpath 1
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 1
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 1
tlpdbopt_file_assocs 1
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 1
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 1
TEXDIR $TEXLIVE_DIR/2018
TEXMFLOCAL $TEXLIVE_DIR/texmf-local
TEXMFSYSCONFIG $TEXLIVE_DIR/2018/texmf-config
TEXMFSYSVAR $TEXLIVE_DIR/2018/texmf-var
"

if [ ! -e "$INSTALL_TL_SUCCESS" ]; then
  tar xf "$INSTALL_TL"

  echo "[$0] Installing TeX Live..."
  "$INSTALL_TL_VERSION"/install-tl --profile=<(echo "$TEXLIVE_PROFILE")
  echo "[$0] Installed TeX Live."

  touch "$INSTALL_TL_SUCCESS"
else
  echo "[$0] Found existing TeX Live installation."
fi

export PATH="$TEXLIVE_BIN:$PATH"

python "$TEXLIVEONFLY" -c latexmk -a "-g -pdf -synctex=1 -interaction=nonstopmode" main.tex

mkdir -p dist
cp *.pdf dist
