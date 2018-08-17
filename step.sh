#!/bin/bash

set -ex

echo "$api_key"
echo "$owner_name"
echo "$app_path"

upload_app() {
  set +e

  curl -# -X POST \
    -H "Authorization: token $api_key" \
    -F "file=@$app_path" \
    "https://deploygate.com/api/users/$owner_name/apps" 

  set -e
  return 0
}

parse_error_field() {
  cat - | ruby -rjson -ne 'puts JSON.parse($_)["error"]'
}

upload_app > output.json
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