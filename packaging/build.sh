#!/bin/bash
# 构建 magpie 的 fnOS 原生应用包（.fpk），双架构输出到 dist/fnos-<架构>/
# 用法：bash packaging/build.sh
#   PKG_VERSION     应用包版本（默认 0.1.4406，用于覆盖安装/升级）
#   MAGPIE_VERSION  上游二进制版本（默认 0.1.4405）
#   MAGPIE_CACHE    下载缓存目录（默认 ~/.cache/magpie-fpk，不写入仓库）
set -euo pipefail

APP_NAME=magpie
PKG_VERSION=${PKG_VERSION:-0.1.4407}
MAGPIE_VERSION=${MAGPIE_VERSION:-0.1.4405}
FNPACK_VERSION=1.2.3

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="${ROOT}/packaging"
CACHE=${MAGPIE_CACHE:-${HOME}/.cache/magpie-fpk}
DIST="${ROOT}/dist"

mkdir -p "${CACHE}" "${DIST}"

# 下载并校验完整性：比对服务端 Content-Length，避免截断的二进制被打进包
download() {
    local url=$1 out=$2
    if [ -s "${out}" ]; then
        echo "已缓存: $(basename "${out}")"
        return 0
    fi
    echo "下载: ${url}"
    curl -fL --retry 5 --retry-delay 3 -o "${out}.part" "${url}"
    local expected actual
    expected=$(curl -sIL "${url}" | tr -d '\r' | awk 'tolower($1)=="content-length:"{n=$2} END{print n}')
    actual=$(stat -c %s "${out}.part")
    if [ -n "${expected}" ] && [ "${expected}" != "${actual}" ]; then
        rm -f "${out}.part"
        echo "下载不完整: 期望 ${expected} 字节，实际 ${actual} 字节" >&2
        exit 1
    fi
    mv "${out}.part" "${out}"
}

# 准备 fnpack
FNPACK=$(command -v fnpack || true)
if [ -z "${FNPACK}" ]; then
    download "https://static2.fnnas.com/fnpack/fnpack-${FNPACK_VERSION}-linux-amd64" \
        "${CACHE}/fnpack-${FNPACK_VERSION}"
    chmod +x "${CACHE}/fnpack-${FNPACK_VERSION}"
    FNPACK="${CACHE}/fnpack-${FNPACK_VERSION}"
fi

build_arch() {
    local arch=$1 platform=$2 outdir=$3
    local bin="${CACHE}/magpie-cli-linux-${arch}-${MAGPIE_VERSION}"
    download "https://github.com/yetone/magpie-releases/releases/download/v${MAGPIE_VERSION}/magpie-cli-linux-${arch}" "${bin}"

    local work="${CACHE}/build-${outdir}"
    rm -rf "${work}"
    mkdir -p "${work}"
    cp -R "${SRC}/." "${work}/"
    cp "${bin}" "${work}/app/magpie"
    chmod +x "${work}/app/magpie" "${work}"/cmd/*
    sed -i "s/^version=.*/version=${PKG_VERSION}/; s/^platform=.*/platform=${platform}/" "${work}/manifest"

    ( cd "${work}" && "${FNPACK}" build )

    mkdir -p "${DIST}/${outdir}"
    mv -f "${work}/${APP_NAME}.fpk" "${DIST}/${outdir}/${APP_NAME}-${PKG_VERSION}-${outdir}.fpk"
    echo "输出: ${DIST}/${outdir}/${APP_NAME}-${PKG_VERSION}-${outdir}.fpk"
}

build_arch amd64 x86 fnos-x86
build_arch arm64 arm fnos-arm64
