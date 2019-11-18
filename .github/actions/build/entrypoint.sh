#!/bin/sh -l

set -e

apk update && \
apk add git && \


echo "mkdir $3"
mkdir $3

echo "$1 $2 -o ./$3/index.html"
sh -c "$1 $2 -o ./$3/index.html"

echo "find src -name '*.png' | cpio -pdm  ./$3"
find src -name '*.png' | cpio -pdm  ./$3

cd ./$3

git init
git config user.name "itggot-daniel-berg"
git config user.email "daniel.berg@ntig.se"

git add . ; git commit -m "Deploy to GitHub Pages"

REPOSITORY_PATH="https://${ACCESS_TOKEN}@github.com/itggot/datalagring.git" &&\

git push --force $REPOSITORY_PATH master:gh-pages