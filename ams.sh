#!/bin/bash

## Copyright (c) 2024, Nuno Nobre, STFC Hartree Centre

## A script that uses Spack to automate the installation of AMS with CUDA support
## on Scafell Pike, the Hartree Centre's supercomputer

### Use python3 as required by Spack

module load python3/3.10

### Get Spack and isolate this installation from any existing system/user settings

git clone --branch=releases/v0.21 https://github.com/spack/spack.git
export SPACK_DISABLE_LOCAL_CONFIG=true
export SPACK_USER_CACHE_PATH=$PWD/tmp/spack
source spack/share/spack/setup-env.sh

### Patch: .so for SLEEF, and newer version, https git link and compilation/linking fixes for AMS

cd spack
git cherry-pick 8c061e5
git cherry-pick 300d53d
git cherry-pick a49b2f4
git apply ../ams.patch
cd -

### Tell Spack about LSF

cat <<EOF > spack/etc/spack/packages.yaml
packages:
  lsf:
    externals:
    - spec: lsf@10.1
      prefix: $EGO_TOP/10.1
EOF

### Install gcc 11.2.0

spack -k install gcc@11.2.0
spack load gcc
spack compiler find

### Install AMS and its dependencies

spack -k install -n ams %gcc@11.2.0 +examples +mpi +torch +verbose +cuda cuda_arch=70 ^openmpi +cuda schedulers=lsf ^py-torch@2.0.1 ^mfem +umpire

### Remove tmp cache

rm -rf $SPACK_USER_CACHE_PATH
