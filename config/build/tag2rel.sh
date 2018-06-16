#!/bin/bash

## Script to extract versioning information from a git tag
usage(){
    usage="Usage: $0 <tag>
  Options:
    <tag> is (optionally) the tag being used to create a release in the form vX.Y.Z(-(alpha|beta|pre|rc)[0-9]+)?(-git[a-fA-F0-9]{6,8})?
  Returns:
    * Major is the current major version number
    * Minor is the current minor version number
    * Patch is the current patch version number
    * Version(version) is the base X.Y.Z version of the tag which is the parent of the commit being built
    * Release(relver) is the release version added to an RPM i.e., X.Y.Z-relver (see https://fedoraproject.org/wiki/Package_Versioning_Examples for examples)
    * FullVersion
    * TagVersion is the full name of the tag which is a parent of this commit
    * Revision(gitrev) is the git revision hash of the commit
    * GitVersion(gitver) e.g., v0.99.0-pre10-2-g47878f-dirty
Major:0 Minor:99 Patch:0 Release:0.3.pre10 Version:0.99.0 FullVersion:v0.99.0-pre10 TagVersion:v0.99.0 Revision:47878ff GitVersion:v0.99.0-pre10-2-g47878f-dirty

  Description:
    This script aims to provide a unique identifier for every built version of a package.
    Whether for a build done by the CI system, or a local build made by a developer, certain information will be encoded
    For an untagged release, gitver will be used to determine the base tag, and will compute the distance from this most recent, adding this as a devX release for python and -0.0.X.dev for the RPM 'Release' tag (alpha|beta|pre|rc)X releases (from the tag) will be built as adding this as a pre-release build (alpha|beta|pre|rc)X release for python and -0.Y.X.(alpha|beta|pre|rc) for the RPM 'Release' tag, where Y indicates 1,2,3,4 for alpha,beta,pre,rc (resp.)
    If the parent tag is a complete tag, the returned tag will be bumped and the Release indicates the number of commits since that tag and the .devX designation
"
    return 0
}

#   list of tags and associated rpm/python release versions:
##  ** Examples:
#        tag name       RPM Release               pre-release
#        v0.2.2         0.2.2 1                   "-<hash>git"
#         * commit 1    0.2.2 1.0.1.dev          "-final.dev1-<hash>git"
#       OR
#         * commit 1    0.2.3 0.0.1.dev          "-dev1-<hash>git"
#         * commit 2    0.2.3 0.0.2.dev          "-dev2-<hash>git"
#         * commit 3    0.2.3 0.0.3.dev          "-dev3-<hash>git"
#         * commit 4    0.2.3 0.0.4.dev          "-dev4-<hash>git"
#        v0.2.3-alpha1  0.2.3 0.1.1.alpha1       "-alpha1-<hash>git"
#         * commit 1    0.2.3 0.1.1.1.alpha1.dev "-alpha1.dev1-<hash>git"
#         * commit 2    0.2.3 0.1.1.2.alpha1.dev "-alpha1.dev2-<hash>git"
#         * commit 3    0.2.3 0.1.1.3.alpha1.dev "-alpha1.dev3-<hash>git"
#        v0.2.3-alpha2  0.2.3 0.1.2.alpha2       "-alpha2-<hash>git"
#        v0.2.3-alpha3  0.2.3 0.1.3.alpha3       "-alpha3-<hash>git"
#        v0.2.3-beta1   0.2.3 0.2.1.beta1        "-beta1-<hash>git"
#        v0.2.3-beta2   0.2.3 0.2.2.beta2        "-beta2-<hash>git"
#        v0.2.3-pre1    0.2.3 0.3.1.pre1         "-pre1-<hash>git"
#        v0.2.3-pre2    0.2.3 0.3.2.pre2         "-pre2-<hash>git"
#        v0.2.3-pre3    0.2.3 0.3.3.pre3         "-pre3-<hash>git"
#        v0.2.3-rc1     0.2.3 0.4.1.rc1          "-rc1-<hash>git"
#        v0.2.3-rc2     0.2.3 0.4.2.rc2          "-rc2-<hash>git"
#        v0.2.3         0.2.3 1                  "-<hash>git"

# if previuos tag is complete, e.g., v0.2.2, bump next version values:
#    Major: 1.0.0
#    Minor: 0.3.0
#    Patch: 0.2.3

# probably better to try to use setuptools_scm, which does this natively, but want something generically applicable

if [ -z ${1+x} ]
then
    version=$(git describe --abbrev=0 --tags --always)
else
    version=$1
fi

relver=1
gitrev=$(git rev-parse --short HEAD)
gitver=$(git describe --abbrev=6 --dirty --always --tags)
tagcommit=$(git rev-list --tags --max-count=1)
lasttag=$(git describe --tags ${tagcommit} )
revision=$(git rev-list ${lasttag}.. --count )

# basic version unit is vX.Y.Z
vre='^v?(.)?([0-9]+).([0-9]+).([0-9]+)'
gre='(git[0-9a-fA-F]{6,8})'

fullver=${version}

if [[ $version =~ $vre$ ]]
then
    basever=$version
    if [ "${revision}" = "0" ]
    then
        relver=1
    else
        ## needs a version bump somehow
        # relver=0.0.$revision.dev
        ## doesn't need a version bump
        relver=1.0.${revision}.dev
        buildtag="-final.dev${revision}"
    fi
    
elif [[ $version =~ $vre ]]
then
    pretag=""

    if [[ "${version##*-}" =~ ^git ]]
    then
        basever=${version%-*}
        version=${version%-*}
        pretag="-git"
        relnum=
    fi

    if [[ "${version##*-}" =~ ^(alpha|beta|pre|rc) ]]
    then
        basever=${version%-*}
        prerel=${version##*-}
        if [[ "${prerel}" =~ ^alpha ]]
        then
            pretag="-alpha"
            relnum=1
        elif [[ "${prerel}" =~ ^beta ]]
        then
            pretag="-beta"
            relnum=2
        elif [[ "${prerel}" =~ ^pre ]]
        then
            pretag="-pre"
            relnum=3
        elif [[ "${prerel}" =~ ^rc ]]
        then
            pretag="-rc"
            relnum=4
        fi
    fi

    tags=( $(git tag -l "*${basever}${pretag}*") )
    ntags=$((${#tags[@]}))
    if [ "${revision}" = "0" ]
    then
        relver=0.${relnum}.${ntags}.${prerel}
    else
        relver=0.${relnum}.${ntags}.${revision}.${prerel}
        buildtag="-${prerel}.dev${revision}"
    fi
else
    basever=untagged
fi

if ! [[ ${basever} =~ "untagged" ]]
then
    version=${basever##v}
    patch=${version##*.}
    version=${version%.*}
    minor=${version##*.}
    major=${version%.*}
    version=${basever##v}
    
else
    version=${basever##v}
    fullver=${version}-${gitrev}git

fi

## Output a single parseable line? or output multiple lines?
echo Major:${major} \
     Minor:${minor} \
     Patch:${patch} \
     Release:${relver} \
     Version:${version} \
     FullVersion:${fullver} \
     TagVersion:${basever} \
     BuildTag:${buildtag} \
     Revision:${gitrev} \
     GitVersion:${gitver}
