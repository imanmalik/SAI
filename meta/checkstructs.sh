#!/bin/bash
#
# Copyright (c) 2021 Microsoft Open Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
#    THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR
#    CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT
#    LIMITATION ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS
#    FOR A PARTICULAR PURPOSE, MERCHANTABILITY OR NON-INFRINGEMENT.
#
#    See the Apache Version 2.0 License for specific language governing
#    permissions and limitations under the License.
#
#    Microsoft would like to thank the following companies for their review and
#    assistance with these files: Intel Corporation, Mellanox Technologies Ltd,
#    Dell Products, L.P., Facebook, Inc., Marvell International Ltd.
#
# @file    checkstructs.sh
#
# @brief   This module defines check structs script
#


# To list git ancestry all comitts (even if there is a tree not single line)
# this can be usefull to build histroy of structs from root (struct lock) to the
# current origin/master and current commit - and it will be possible to fix
# mistakes.

# examples below are to show how to get correct git history tree
# git log --graph --oneline --ancestry-path c388490^..0b90765 | cat
# git rev-list --ancestry-path  c388490^..0b90765

# If we will have our base commit, we will assume that each previous commit
# followed metadata check, and then we can use naive approach for parsing struct
# values instead of doing gcc compile whch can take long time. With this
# approach we should be able to build entire history from base commit throug
# all commits up to the current PR. This will sure that there will be no
# abnormalities if some structs will be removed and then added again with
# different value. This will also help to track the issue if two PRs will pass
# validation but after they will be merged they could potentially cause struct
# value issue and this approach will catch that.
#
# Working throug 25 commits takes about 0.4 seconds + parsing so it seems like
# not a hudge time to make sure all commits are safe and even if we get at some
# point that this will be "too slow", having all history, we can sometimes
# produce "known" history with structs values and keep that file as a reference
# and load it at begin, and start checking commits from one of the future
# commits, basicially reducing processing time to zero.

# Just for sanity we can also keep headers check to 1 commit back and also
# maybe we can add one gcc check current to history,

set -e

# 1. get all necessary data to temp directory for future processing
# 2. pass all interesting commits to processor to build history

function clean_temp_dir()
{
    rm -rf temp
}

function create_temp_dir()
{
    mkdir temp
}

function checkout_inc_directories()
{
    echo "git checkout work tree commits:" $LIST

    for commit in $LIST
    do
        #echo working on commit $commit

        mkdir temp/commit-$commit
        mkdir temp/commit-$commit/inc

        git --work-tree=temp/commit-$commit checkout $commit inc 2>/dev/null

    done
}

function create_commit_list()
{
    local begin=$1
    local end=$2

    echo "ancestry graph"

    # NOTE: origin/master should be changed if this file is on different branch

    git --no-pager log --graph --oneline --ancestry-path  origin/master^..HEAD

    echo "git rev list from $begin to $end"

    LIST=$(git rev-list --ancestry-path ${begin}^..${end} | xargs -n 1 git rev-parse --short | tac)
}

function check_structs_history()
{
    perl structs.pl $LIST
}

#
# MAIN
#

# BEGIN_COMMIT is the commit from we want structs to be backward compatible

BEGIN_COMMIT=97a1e02 # v1.11.0
END_COMMIT=HEAD

clean_temp_dir
create_temp_dir
create_commit_list $BEGIN_COMMIT $END_COMMIT
checkout_inc_directories
check_structs_history
