#!/bin/bash

readonly STEP_VERSION=1.1.1
readonly output_file="output.json"

upload_app() {
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
    -o "$output_file" \
    -H "Authorization: token $api_key" \
    -H "Accept: application/json" \
    -A "DeployGateUploadAppBitriseStep/$STEP_VERSION" \
    "${fields[@]}" \
    "https://deploygate.com/api/users/$owner_name/apps"
}

parse_error_field() {
  cat - | ruby -rjson -ne 'puts JSON.parse($_)["error"]'
}

upload_app # this will create the `output.json``

envman add --key DEPLOYGATE_UPLOAD_APP_STEP_RESULT_JSON --valuefile "$output_file"

cat "$output_file"

[[ "$(cat output.json | parse_error_field)" == "false" ]]