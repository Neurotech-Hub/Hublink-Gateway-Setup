#!/bin/bash

# git-pull.sh
git reset --hard HEAD
git clean -fd
git pull origin <branch>
