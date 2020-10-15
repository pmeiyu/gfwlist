#!/usr/bin/env bash

# This script decodes the base64-encoded GFWList and migrates its git revision
# history to a new git repository.
#
# License: GPLv3
# Copyright 2017, 2020 Peng Mei Yu


SRC_REPO=../gfwlist-base64
DST_REPO=.
since="2000-01-01 00:00:00 +0000"

# Get git revision history.
revision_log=$(git -C $SRC_REPO log --reverse --format="%H|%an|%ae|%ai|%s" --since "$since")

IFS='|'
while read hash author_name author_email date subject; do
    export GIT_AUTHOR_NAME=$author_name
    export GIT_AUTHOR_EMAIL=$author_email
    export GIT_AUTHOR_DATE=$date
    export GIT_COMMITTER_NAME=$author_name
    export GIT_COMMITTER_EMAIL=$author_email
    export GIT_COMMITTER_DATE=$date

    # Some old commit messages are base64 encoded.
    if echo $subject | base64 -d >/dev/null; then
        subject=$(echo $subject | base64 -d)
    fi

    # Decode gfwlist.txt.
    git -C $SRC_REPO show $hash:gfwlist.txt | base64 -d >$DST_REPO/gfwlist.txt

    # Add decoded file to new repository.
    git -C $DST_REPO add gfwlist.txt
    git -C $DST_REPO commit --allow-empty-message --no-gpg-sign --message "$subject"
done <<<$revision_log
