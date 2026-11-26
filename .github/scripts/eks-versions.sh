#!/usr/bin/env bash
#
# Checks the EKS API for a newer Kubernetes version and newer addon versions,
# and updates the module defaults in variables.tf and README.md in place.
#
# The addon versions are always resolved against the Kubernetes version the
# module will default to, so a Kubernetes bump and its addon bumps land
# together. If any tracked addon has not yet been published for a new
# Kubernetes version, the Kubernetes bump is held back.
#
# Requires: aws cli (with eks:DescribeClusterVersions and
# eks:DescribeAddonVersions), perl, GNU-compatible `sort -V`.
#
# Environment:
#   ADDON_STRATEGY   latest (default) - newest addon version for the k8s version
#                    default          - the version EKS marks as the default
#   VARIABLES_FILE   path to variables.tf (default: variables.tf)
#   README_FILE      path to README.md (default: README.md)
#   SUMMARY_FILE     where to write the markdown PR body (default: pr-body.md)
#   GITHUB_OUTPUT    set by GitHub Actions; receives changed/title outputs

set -euo pipefail

ADDON_STRATEGY="${ADDON_STRATEGY:-latest}"
VARIABLES_FILE="${VARIABLES_FILE:-variables.tf}"
README_FILE="${README_FILE:-README.md}"
SUMMARY_FILE="${SUMMARY_FILE:-pr-body.md}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

# Tracked addons as "<eks addon name>:<terraform variable name>". The variable
# must contain a `version = optional(string, "<version>")` attribute.
ADDONS=(
  "aws-ebs-csi-driver:ebs_csi_driver"
  "aws-efs-csi-driver:efs_csi_driver"
)

log() { echo "[eks-versions] $*" >&2; }

# Returns success when $2 is a strictly newer version than $1
is_newer() {
  [[ "$1" != "$2" ]] && [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$2" ]]
}

current_kubernetes_version() {
  awk '/^variable "kubernetes_version"/ { found = 1 }
       found && $1 == "default" { gsub(/"/, "", $3); print $3; exit }' "${VARIABLES_FILE}"
}

current_addon_version() {
  awk -v var="$1" '$0 ~ "^variable \"" var "\"" { found = 1 }
       found && /version = optional\(string,/ {
         match($0, /"[^"]+"/); print substr($0, RSTART + 1, RLENGTH - 2); exit
       }' "${VARIABLES_FILE}"
}

latest_kubernetes_version() {
  aws eks describe-cluster-versions \
    --version-status STANDARD_SUPPORT \
    --query 'clusterVersions[].clusterVersion' \
    --output text | tr '\t' '\n' | grep -v '^$' | sort -V | tail -n1
}

# Prints the addon version for the given Kubernetes version, or nothing if
# the addon has not been published for it.
resolve_addon_version() {
  local addon="$1" k8s="$2" result

  case "${ADDON_STRATEGY}" in
    latest)
      result=$(aws eks describe-addon-versions \
        --addon-name "${addon}" \
        --kubernetes-version "${k8s}" \
        --query 'addons[0].addonVersions[].addonVersion' \
        --output text | tr '\t' '\n' | grep -v -e '^$' -e '^None$' | sort -V | tail -n1 || true)
      ;;
    default)
      # shellcheck disable=SC2016 # backticks are a JMESPath literal
      result=$(aws eks describe-addon-versions \
        --addon-name "${addon}" \
        --kubernetes-version "${k8s}" \
        --query 'addons[0].addonVersions[?compatibilities[?defaultVersion==`true`]].addonVersion | [0]' \
        --output text)
      [[ "${result}" == "None" ]] && result=""
      ;;
    *)
      log "unknown ADDON_STRATEGY '${ADDON_STRATEGY}' (expected latest or default)"
      exit 1
      ;;
  esac

  echo "${result}"
}

# Replaces a literal string in a file
replace_literal() {
  local file="$1" old="$2" new="$3"
  OLD="${old}" NEW="${new}" perl -pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "${file}"
}

update_kubernetes_version() {
  local old="$1" new="$2"
  OLD="${old}" NEW="${new}" perl -0pi -e \
    's/(variable "kubernetes_version" \{.*?default\s*=\s*")\Q$ENV{OLD}\E"/${1}$ENV{NEW}"/s' \
    "${VARIABLES_FILE}"
  # terraform-docs renders the default as `"1.xx"` on the input's table row
  OLD="${old}" NEW="${new}" perl -pi -e \
    's/`"\Q$ENV{OLD}\E"`/`"$ENV{NEW}"`/ if /input_kubernetes_version/' \
    "${README_FILE}"
}

main() {
  local current_k8s latest_k8s target_k8s
  local changes=() kubernetes_changed=false

  current_k8s=$(current_kubernetes_version)
  [[ -n "${current_k8s}" ]] || { log "could not read kubernetes_version from ${VARIABLES_FILE}"; exit 1; }

  latest_k8s=$(latest_kubernetes_version)
  [[ -n "${latest_k8s}" ]] || { log "could not determine latest EKS Kubernetes version"; exit 1; }
  log "kubernetes: current=${current_k8s} latest=${latest_k8s}"

  target_k8s="${current_k8s}"
  if is_newer "${current_k8s}" "${latest_k8s}"; then
    target_k8s="${latest_k8s}"
    # Hold back the Kubernetes bump until every tracked addon supports it
    for entry in "${ADDONS[@]}"; do
      addon="${entry%%:*}"
      if [[ -z "$(resolve_addon_version "${addon}" "${latest_k8s}")" ]]; then
        log "${addon} has no version for kubernetes ${latest_k8s} yet; holding kubernetes at ${current_k8s}"
        target_k8s="${current_k8s}"
        break
      fi
    done
  fi

  if [[ "${target_k8s}" != "${current_k8s}" ]]; then
    update_kubernetes_version "${current_k8s}" "${target_k8s}"
    kubernetes_changed=true
    changes+=("| Kubernetes | \`${current_k8s}\` | \`${target_k8s}\` | [EKS release notes](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) |")
  fi

  for entry in "${ADDONS[@]}"; do
    addon="${entry%%:*}"
    variable="${entry##*:}"

    current=$(current_addon_version "${variable}")
    [[ -n "${current}" ]] || { log "could not read ${variable}.version from ${VARIABLES_FILE}"; exit 1; }

    resolved=$(resolve_addon_version "${addon}" "${target_k8s}")
    log "${addon}: current=${current} resolved=${resolved:-<none>} (kubernetes ${target_k8s}, strategy ${ADDON_STRATEGY})"

    if [[ -n "${resolved}" ]] && is_newer "${current}" "${resolved}"; then
      replace_literal "${VARIABLES_FILE}" "${current}" "${resolved}"
      replace_literal "${README_FILE}" "${current}" "${resolved}"
      changes+=("| ${addon} | \`${current}\` | \`${resolved}\` | [Addon docs](https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html) |")
    fi
  done

  if [[ ${#changes[@]} -eq 0 ]]; then
    log "everything is up to date"
    echo "changed=false" >> "${GITHUB_OUTPUT}"
    return 0
  fi

  local title
  if [[ "${kubernetes_changed}" == "true" ]]; then
    title="chore(deps): update eks kubernetes version to ${target_k8s}"
  else
    title="chore(deps): update eks addon versions for kubernetes ${target_k8s}"
  fi

  {
    echo "## EKS version updates"
    echo
    echo "Updates the module defaults to the versions currently published by Amazon EKS."
    echo
    echo "| Component | From | To | Notes |"
    echo "|---|---|---|---|"
    printf '%s\n' "${changes[@]}"
    echo
    echo "Addon versions were resolved for Kubernetes \`${target_k8s}\` using the \`${ADDON_STRATEGY}\` strategy."
    if [[ "${kubernetes_changed}" == "true" ]]; then
      echo
      echo "> [!WARNING]"
      echo "> This changes the default Kubernetes version. Consumers relying on the default will be upgraded; review the upstream changelog and consider a minor release."
    fi
    echo
    echo "_Generated by the \`EKS Version Check\` workflow._"
  } > "${SUMMARY_FILE}"

  {
    echo "changed=true"
    echo "kubernetes_changed=${kubernetes_changed}"
    echo "title=${title}"
  } >> "${GITHUB_OUTPUT}"

  log "${title}"
}

main "$@"
