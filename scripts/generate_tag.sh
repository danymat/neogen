#!/bin/bash
# Copied from https://github.com/nvim-neorg/neorg/blob/main/scripts/generate_tag.sh

current_version=$(nvim --headless --noplugin -u ./scripts/minimal_init.vim -c 'luafile ./scripts/get_version.lua' -c 'qa' 2>&1 | tr -d \")

# get current commit hash for tag
commit=$(git rev-parse HEAD)

# Creates a new tag for current version
push_tag() {

curl -s -X POST https://api.github.com/repos/danymat/neogen/git/refs \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF
{
  "ref": "refs/tags/$current_version",
  "sha": "$commit"
}
EOF

echo "Generated new tag: $current_version"
}

echo "Current version: $current_version"
echo "Last commit: $commit"
echo "Existing tags: $(git tag -l)"

if [ $(git tag -l "$current_version") ]; then
    echo "No new Neogen version (current: $current_version)"
    exit 0
else
    push_tag
fi
