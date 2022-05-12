#!/bin/bash

readonly STEP_VERSION=1.1.2
readonly output_file="output.json"

info() {
  echo "[INFO] $@"
}

err() {
  echo "[ERROR] $@" 1>&2
}

fatal() {
  err "$@"
  exit 1
}

upload_app() {
  local -r all_fields=(
      "file=@$app_path"
      "message=$message"
      "distribution_key=$distribution_key"
      "distribution_name=$distribution_name"
      "release_note=$release_note"
      "disable_notify=$disable_notify"
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

  curl -L# -X POST \
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

if [[ ! -f "$app_path" ]]; then
  fatal "$app_path is not found. Please make sure the application file has been successfuly created in the previous steps."
fi

# this will create the `output.json``
if ! upload_app; then
  fatal "your upload request failed and didn't reach to the server due to misconfiguration."
fi

envman add --key DEPLOYGATE_UPLOAD_APP_STEP_RESULT_JSON --valuefile "$output_file"

cat "$output_file"
echo

if [[ "$(cat output.json | parse_error_field)" == "false" ]]; then
  info "Uploaded successfully."
else
  fatal "Upload failed."
fi
