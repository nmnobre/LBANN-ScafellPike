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

### Try to install LBANN and its dependencies for the 1st time

spack -k install -n lbann@develop %gcc@11.2.0 +distconv +numpy +vision +cuda cuda_arch=70 ^openmpi schedulers=lsf ^hydrogen@develop+al ^aluminum@master ^py-numpy ^spdlog@1.11.0

### Workaround missing CUDA for PMIx

export CUDA_DIR=$(spack find --paths cuda | tail -1 | awk '{print $2}')
cd $CUDA_DIR/lib64
ln -sf stubs/libnvidia-ml.so libnvidia-ml.so.1
cd -

### 2nd time

spack -k install -n lbann@develop %gcc@11.2.0 +distconv +numpy +vision +cuda cuda_arch=70 ^openmpi schedulers=lsf ^hydrogen@develop+al ^aluminum@master ^py-numpy ^spdlog@1.11.0

### Workaround failing CMake for DiHydrogen

export Hydrogen_DIR=$(spack find --paths hydrogen | tail -1 | awk '{print $2}')

### 3rd time ('s a charm)

spack -k install -n lbann@develop %gcc@11.2.0 +distconv +numpy +vision +cuda cuda_arch=70 ^openmpi schedulers=lsf ^hydrogen@develop+al ^aluminum@master ^py-numpy ^spdlog@1.11.0

### Revert CUDA workaround and remove tmp cache

unlink $CUDA_DIR/lib64/libnvidia-ml.so.1
rm -rf $SPACK_USER_CACHE_PATH
