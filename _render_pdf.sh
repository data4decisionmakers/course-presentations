#!/usr/bin/env bash
#
# _render_pdf.sh
#
# Convert the rendered reveal.js slide decks in _slides/ into PDF files using
# decktape (https://github.com/astefanutti/decktape) via Docker.
#
# PDFs are written to the pdf/ directory in the repo root, inside a sub-folder
# named after the deck's track (e.g.
# _slides/data-concepts-applications/11-fair/index.html
# -> pdf/data-concepts-applications/11-fair.pdf).
#
# Usage:
#   ./_render_pdf.sh                 # convert every deck found in _slides/
#   ./_render_pdf.sh --render        # run `quarto render` first, then convert
#   ./_render_pdf.sh 11-fair 10-epi-stats
#                                    # convert only the named deck(s)
#
# Requirements: Docker (the decktape image is pulled automatically on first run).

set -euo pipefail

# configuration ----------------------------------------------------------------

# Resolve the repo root as the directory containing this script, so the script
# works no matter where it is invoked from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLIDES_DIR="${REPO_ROOT}/_slides"
PDF_DIR="${REPO_ROOT}/pdf"
DECKTAPE_IMAGE="astefanutti/decktape"

# parse arguments --------------------------------------------------------------

RENDER=0
DECK_FILTERS=()
for arg in "$@"; do
  case "$arg" in
    --render) RENDER=1 ;;
    -h|--help)
      sed -n '3,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) DECK_FILTERS+=("$arg") ;;
  esac
done

# pre-flight checks ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH." >&2
  exit 1
fi

if [[ "${RENDER}" -eq 1 ]]; then
  echo ">> Rendering decks with quarto..."
  (cd "${REPO_ROOT}" && quarto render)
fi

if [[ ! -d "${SLIDES_DIR}" ]]; then
  echo "Error: ${SLIDES_DIR} does not exist. Run 'quarto render' first" >&2
  echo "       (or re-run this script with --render)." >&2
  exit 1
fi

mkdir -p "${PDF_DIR}"

# convert each deck ------------------------------------------------------------

# Run the container as the current host user so the generated PDFs are owned by
# you rather than by root. Some environments (e.g. CI runners, where the host
# uid has no home directory inside the container) must NOT remap the user, or
# Chromium fails to launch ("chrome_crashpad_handler: --database is required").
# Set DECKTAPE_NO_USER_REMAP=1 to run as the image's default (root) user.
USER_FLAG=()
if [[ -z "${DECKTAPE_NO_USER_REMAP:-}" ]]; then
  USER_FLAG=(--user "$(id -u):$(id -g)")
fi

converted=0
while IFS= read -r html; do
  deck_dir="$(dirname "${html}")"
  deck_name="$(basename "${deck_dir}")"

  # If deck name filters were given, skip anything that doesn't match.
  if [[ "${#DECK_FILTERS[@]}" -gt 0 ]]; then
    match=0
    for f in "${DECK_FILTERS[@]}"; do
      [[ "${deck_name}" == "${f}" ]] && match=1
    done
    [[ "${match}" -eq 0 ]] && continue
  fi

  # Path to the HTML relative to _slides, as seen inside the container mount.
  rel="${html#"${SLIDES_DIR}/"}"

  # Track = the deck's parent path under _slides (e.g. data-concepts-applications).
  # Mirror it as a sub-folder under pdf/ so decks with the same folder name in
  # different tracks don't collide.
  track="$(dirname "${rel%/index.html}")"
  mkdir -p "${PDF_DIR}/${track}"

  echo ">> ${track}/${deck_name}"
  docker run --rm -t "${USER_FLAG[@]}" \
    -v "${SLIDES_DIR}:/slides" \
    -v "${PDF_DIR}:/pdf" \
    "${DECKTAPE_IMAGE}" reveal \
    --chrome-arg=--no-sandbox \
    --chrome-arg=--disable-dev-shm-usage \
    "/slides/${rel}" \
    "/pdf/${track}/${deck_name}.pdf"

  converted=$((converted + 1))
done < <(find "${SLIDES_DIR}" -name index.html | sort)

echo ">> Done. ${converted} PDF(s) written to ${PDF_DIR}/"
