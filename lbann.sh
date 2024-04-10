#!/bin/bash

## Copyright (c) 2024, Nuno Nobre, STFC Hartree Centre

## A script that uses Spack to automate the installation of LBANN with CUDA support
## on Scafell Pike, the Hartree Centre's supercomputer

### Use python3 as required by Spack

module load python3/3.10

### Get Spack and isolate this installation from any existing system/user settings

git clone --depth=100 --branch=releases/v0.21 https://github.com/spack/spack.git
export SPACK_DISABLE_LOCAL_CONFIG=true
export SPACK_USER_CACHE_PATH=$PWD/tmp/spack
source spack/share/spack/setup-env.sh

### Install gcc 11.2.0

spack -k install gcc@11.2.0
spack load gcc
spack compiler find

### Try to install LBANN and its dependencies for the 1st time

spack -k install lbann@develop %gcc@11.2.0 +numpy +cuda cuda_arch=70 ^hydrogen@develop+al ^aluminum@master ^py-numpy

### Workaround missing CUDA for PMIx

export CUDA_DIR=$(spack find --paths cuda | head -2 | tail -1 | awk '{print $2}')
cd $CUDA_DIR/lib64
ln -sf stubs/libnvidia-ml.so libnvidia-ml.so.1
cd -

### 2nd time

spack -k install lbann@develop %gcc@11.2.0 +numpy +cuda cuda_arch=70 ^hydrogen@develop+al ^aluminum@master ^py-numpy

### Workaround failing CMake for DiHydrogen

export Hydrogen_DIR=$(spack find --paths hydrogen | head -2 | tail -1 | awk '{print $2}')

### 3rd time ('s a charm)

spack -k install lbann@develop %gcc@11.2.0 +numpy +cuda cuda_arch=70 ^hydrogen@develop+al ^aluminum@master ^py-numpy

### Revert CUDA workaround and remove tmp cache

unlink $CUDA_DIR/lib64/libnvidia-ml.so.1
rm -rf $SPACK_USER_CACHE_PATH
