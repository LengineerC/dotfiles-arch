#!/bin/bash

commit_msg=${1:-$(date "+%Y-%m-%d %H:%M:%S")}

echo "Pushing commit..."

(
  cd "$(chezmoi source-path)" || exit 1

  git add . &&
    git commit -m "$commit_msg" &&
    git push
)

echo "Done."
