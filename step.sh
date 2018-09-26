#!/bin/bash

STEP_VERSION=1.0.0

set -ex

upload_app() {
  set +ex

  local -r all_fields=(
      "file=@$app_path"
      "message=$message"
      "distribution_key=$distribution_key"
      "distribution_name=$distribution_name"
      "release_note=$release_note"
      "disable_notify=$disable_notify"
      "visibility=$visibility"
  )

  local field= fields=()

  for field in "${all_fields[@]}"; do
    if [[ "$field" =~ ^.*=$ ]]; then
      # skip
      continue
    else
      fields+=("-F")
      fields+=("$field")
    fi
  done

  curl -# -X POST \
    -H "Authorization: token $api_key" \
    -A "DeployGateUploadAppBitriseStep/$STEP_VERSION" \
    "${fields[@]}" \
    "https://deploygate.com/api/users/$owner_name/apps" > output.json

  set -ex
  return 0
}

parse_error_field() {
  cat - | ruby -rjson -ne 'puts JSON.parse($_)["error"]'
}

upload_app # this will create the `output.json``

envman add --key DEPLOYGATE_UPLOAD_APP_STEP_RESULT_JSON < output.json

if [[ "$(cat output.json | parse_error_field)" == "false" ]]; then
  # upload successfully
  cat output.json
  exit 0
else
  # WTF
  cat output.json
  exit 1
fi