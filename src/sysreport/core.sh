#!/usr/bin/env bash

SYSREPORT_NAME="sysreport"
SYSREPORT_DESCRIPTION="Linux server audit and operations summary"
SYSREPORT_VERSION="${SYSREPORT_VERSION:-dev}"

if [[ -z "${SYSREPORT_ROOT:-}" ]]; then
  SYSREPORT_ROOT="$(cd -- "${SYSREPORT_LIB_DIR:-$(pwd)}/../.." >/dev/null 2>&1 && pwd -P)"
fi

if [[ -n "${SYSREPORT_LIB_DIR:-}" && -f "$SYSREPORT_LIB_DIR/VERSION" ]]; then
  SYSREPORT_VERSION="$(tr -d '[:space:]' < "$SYSREPORT_LIB_DIR/VERSION")"
elif [[ -f "$SYSREPORT_ROOT/VERSION" ]]; then
  SYSREPORT_VERSION="$(tr -d '[:space:]' < "$SYSREPORT_ROOT/VERSION")"
fi

SYSREPORT_SECTION_IDS=()
SYSREPORT_SECTION_TITLES=()
SYSREPORT_SECTION_FUNCS=()
SYSREPORT_SELECTED_SECTIONS=()
SYSREPORT_COLOR=1

if [[ ! -t 1 || -n "${NO_COLOR:-}" || "${TERM:-}" == "dumb" ]]; then
  SYSREPORT_COLOR=0
fi

sysreport_use_color() {
  [[ "$SYSREPORT_COLOR" -eq 1 ]]
}

sysreport_color() {
  local code="$1"
  if sysreport_use_color; then
    printf '\033[%sm' "$code"
  fi
}

sysreport_refresh_colors() {
  SR_RESET="$(sysreport_color 0)"
  SR_BOLD="$(sysreport_color 1)"
  SR_BLUE="$(sysreport_color '0;34')"
  SR_CYAN="$(sysreport_color '0;36')"
  SR_GREEN="$(sysreport_color '0;32')"
  SR_YELLOW="$(sysreport_color '1;33')"
  SR_RED="$(sysreport_color '0;31')"
}

sysreport_refresh_colors

sysreport_have() {
  command -v "$1" >/dev/null 2>&1
}

sysreport_read_os_release() {
  if [[ -r /etc/os-release ]]; then
    (
      # shellcheck disable=SC1091
      source /etc/os-release
      printf '%s\n' "${PRETTY_NAME:-${NAME:-Linux}}"
    )
  else
    uname -s
  fi
}

sysreport_register_section() {
  local id="$1" title="$2" fn="$3"
  SYSREPORT_SECTION_IDS+=("$id")
  SYSREPORT_SECTION_TITLES+=("$title")
  SYSREPORT_SECTION_FUNCS+=("$fn")
}

sysreport_is_selected() {
  local id="$1" selected
  if [[ "${#SYSREPORT_SELECTED_SECTIONS[@]}" -eq 0 ]]; then
    return 0
  fi

  for selected in "${SYSREPORT_SELECTED_SECTIONS[@]}"; do
    [[ "$selected" == "$id" ]] && return 0
  done

  return 1
}

sysreport_header() {
  printf '%s\n' "${SR_BLUE}${SR_BOLD}============================================================${SR_RESET}"
  printf '%s\n' "${SR_CYAN}${SR_BOLD}  SysReport ${SYSREPORT_VERSION} - ${SYSREPORT_DESCRIPTION}${SR_RESET}"
  printf '%s\n' "${SR_BLUE}${SR_BOLD}============================================================${SR_RESET}"
}

sysreport_section() {
  printf '\n%s\n' "${SR_BLUE}${SR_BOLD}-- $1 --${SR_RESET}"
}

sysreport_item() {
  printf '%b%s:%b %s\n' "${SR_GREEN}" "$1" "${SR_RESET}" "${2:-}"
}

sysreport_ok() {
  printf '  [%bOK%b] %s\n' "$SR_GREEN" "$SR_RESET" "$1"
}

sysreport_warn() {
  printf '  [%bWARN%b] %s\n' "$SR_YELLOW" "$SR_RESET" "$1"
}

sysreport_fail() {
  printf '  [%bFAIL%b] %s\n' "$SR_RED" "$SR_RESET" "$1"
}

sysreport_unknown() {
  printf '  [%bSKIP%b] %s\n' "$SR_YELLOW" "$SR_RESET" "$1"
}

sysreport_usage() {
  cat <<EOF
SysReport - Linux server audit and operations summary

Usage:
  sysreport [options]

Options:
  -h, --help              Show this help message
  -v, --version           Show version
      --no-color          Disable colored output
      --list-sections     List available report sections
      --section <id>      Run one section; repeat to run multiple sections

Examples:
  sysreport
  sysreport --section system --section security
  NO_COLOR=1 sysreport
EOF
}

sysreport_list_sections() {
  local i
  for i in "${!SYSREPORT_SECTION_IDS[@]}"; do
    printf '%-14s %s\n' "${SYSREPORT_SECTION_IDS[$i]}" "${SYSREPORT_SECTION_TITLES[$i]}"
  done
}

sysreport_parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)
        sysreport_usage
        exit 0
        ;;
      -v|--version)
        printf '%s\n' "$SYSREPORT_VERSION"
        exit 0
        ;;
      --no-color)
        SYSREPORT_COLOR=0
        ;;
      --list-sections)
        sysreport_list_sections
        exit 0
        ;;
      --section)
        if [[ -z "${2:-}" ]]; then
          echo "sysreport: --section requires a section id" >&2
          exit 2
        fi
        SYSREPORT_SELECTED_SECTIONS+=("$2")
        shift
        ;;
      *)
        echo "sysreport: unknown option: $1" >&2
        echo "Try 'sysreport --help'." >&2
        exit 2
        ;;
    esac
    shift
  done
}

sysreport_main() {
  local i fn matched=0
  sysreport_parse_args "$@"
  sysreport_refresh_colors
  sysreport_header

  for i in "${!SYSREPORT_SECTION_IDS[@]}"; do
    if sysreport_is_selected "${SYSREPORT_SECTION_IDS[$i]}"; then
      matched=1
      fn="${SYSREPORT_SECTION_FUNCS[$i]}"
      "$fn"
    fi
  done

  if [[ "$matched" -eq 0 ]]; then
    echo "sysreport: no matching sections selected" >&2
    exit 2
  fi

  printf '\n%s\n' "${SR_BLUE}${SR_BOLD}============================================================${SR_RESET}"
  printf '%s\n' "${SR_GREEN}${SR_BOLD}Report complete.${SR_RESET}"
}
