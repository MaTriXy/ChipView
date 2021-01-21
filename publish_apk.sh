#!/usr/bin/env bash
if [ "$TRAVIS_PULL_REQUEST" = false ]; then
  if [ "$TRAVIS_TAG" ]; then
    cd $TRAVIS_BUILD_DIR/app/build/outputs/apk/release/

    printf "\n\nGetting tag information\n"
    tagInfo=$(
      curl \
        -H "Authorization: token $GITHUB_API_KEY" \
        "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/releases/tags/${TRAVIS_TAG}"
    )
    printf "\n\nRelease data: $tagInfo\n"
    releaseId="$(echo "$tagInfo" | jq --compact-output ".id")"

    releaseNameOrg="$(echo "$tagInfo" | jq --compact-output ".tag_name")"
    releaseName=$(echo ${releaseNameOrg} | cut -d "\"" -f 2)

    ln=$"%0D%0A"
    tab=$"%09"

    repoName=$(echo ${TRAVIS_REPO_SLUG} | cut -d / -f 2)

    printf "\n"

    for apk in $(find *.apk -type f); do
      FILE="$apk"
      printf "\n\nUploading: $FILE ... \n"
      upload=$(
        curl \
          -H "Authorization: token $GITHUB_API_KEY" \
          -H "Content-Type: $(file -b --mime-type $FILE)" \
          --data-binary @$FILE \
          --upload-file $FILE \
          "https://uploads.github.com/repos/${TRAVIS_REPO_SLUG}/releases/${releaseId}/assets?name=$(basename $FILE)&access_token=${GITHUB_API_KEY}"
      )

      printf "\n\nUpload Result: $upload\n"

      url="$(echo "$upload" | jq --compact-output ".browser_download_url")"
      url=$(echo ${url} | cut -d "\"" -f 2)
      url=$(echo "${url//\"\r\n\"/$ln}")
      url=$(echo "${url//'\r\n'/$ln}")
      url=$(echo "${url//\\r\\n/$ln}")

      if [[ ! -z "$url" && "$url" != " " && "$url" != "null" ]]; then
        printf "\nAPK url: $url"
        printf "\n\nFinished uploading APK(s)\n"
      else
        printf "\n\nNo file was uploaded\n"
      fi
    done
  else
    printf "\n\nSkipping APK(s) upload because this commit does not have a tag\n"
  fi
else
  printf "\n\nSkipping APK(s) upload because this is just a pull request\n"
fi