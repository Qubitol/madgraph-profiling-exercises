# syntax=docker/dockerfile:1
# =============================================================================
# Dockerfile for "Profiling with perf and Flamegraphs" lectures at iCSC26
# MadGraph5_aMC@NLO + CUDACPP plugin + perf + FlameGraph
# =============================================================================
#
# BUILD:
#   docker build -t <image> .
#
# RUN (perf requires elevated privileges):
#   docker run -it --rm \
#     --privileged \
#     --pid=host \
#     ghcr.io/Qubitol/madgraph-profiling-exercises:latest
#
# NOTE: The host must also have perf_event_paranoid set to allow profiling:
#   sudo sysctl kernel.perf_event_paranoid=-1
#
# =============================================================================

FROM ubuntu:24.04

LABEL maintainer="Daniele Massaro"
LABEL description="MadGraph5 + CUDACPP + perf + FlameGraph ready for the lectures \"Profiling with perf and Flamegraphs\""

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    gfortran \
    make \
    python3 \
    python3-pip \
    python3-six \
    linux-tools-common \
    linux-tools-generic \
    perl \
    wget \
    curl \
    ca-certificates \
    git \
    nano \
    vim-tiny \
    procps \
    less \
    && rm -rf /var/lib/apt/lists/*

# ── perf workaround ─────────────────────────────────────────────────────────
# Ubuntu's /usr/bin/perf is a wrapper that requires a kernel-version match.
# Inside a container the host kernel never matches. Bypass the wrapper by
# symlinking directly to the actual perf binary.
RUN PERF_BIN=$(find /usr/lib/linux-tools* -name "perf" -type f 2>/dev/null | head -1) && \
    if [ -n "$PERF_BIN" ]; then \
      ln -sf "$PERF_BIN" /usr/local/bin/perf ; \
    fi

# ── Create user ──────────────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash user
WORKDIR /home/user

# ── FlameGraph ───────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/brendangregg/FlameGraph.git \
      /opt/FlameGraph

ENV FLAMEGRAPH_DIR=/opt/FlameGraph
ENV PATH="${FLAMEGRAPH_DIR}:${PATH}"

# ── MadGraph5 ────────────────────────────────────────────────────────────────
ARG MG5_VERSION=3.6.6
ARG MG5_NAME=mg5amcnlo-${MG5_VERSION}
ARG MG5_TARBALL=v${MG5_VERSION}.tar.gz
ARG MG5_URL=https://github.com/mg5amcnlo/mg5amcnlo/archive/refs/tags/${MG5_TARBALL}

RUN cd /home/user && \
    wget -q "${MG5_URL}" && \
    tar xzf "${MG5_TARBALL}" && \
    mv ${MG5_NAME} MadGraph5 && \
    rm -f "${MG5_TARBALL}" && \
    rm -f MadGraph5/bin/create_release.py

# ── CUDACPP plugin ───────────────────────────────────────────────────────────
ARG MG4GPU_NAME=madgraph4gpu
ARG MG4GPU_REPO=https://github.com/madgraph5/${MG4GPU_NAME}.git
ARG MG4GPU_TAG=icsc26
RUN cd /home/user && \
    git clone --depth 1 ${MG4GPU_REPO} -b ${MG4GPU_TAG} ${MG4GPU_NAME} && \
    cp -r ${MG4GPU_NAME}/epochX/cudacpp/CODEGEN/PLUGIN/CUDACPP_SA_OUTPUT /home/user/MadGraph5/PLUGIN/CUDACPP_OUTPUT && \
    rm -r ${MG4GPU_NAME}

# ── perf check script ───────────────────────────────────────────────────────
COPY check_perf.sh /home/user/check_perf.sh
RUN chmod +x /home/user/check_perf.sh

# ── Set ownership ────────────────────────────────────────────────────────────
RUN chown -R user:user /home/user

# ── Welcome message ──────────────────────────────────────────────────────────
ENV TERM=xterm-256color

RUN cat > /home/user/.welcome << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║        Profiling with perf and Flamegraphs - Ready to go!        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  MadGraph5:     ~/MadGraph5/                                     ║
║  FlameGraph:    $FLAMEGRAPH_DIR/ (also in PATH)                  ║
║                                                                  ║
║  MG5_aMC@NLO version: 3.6.6                                      ║
║  CUDACPP tag:         icsc26                                     ║
║                                                                  ║
║  Quick check:                                                    ║
║    ./check_perf.sh         # verify perf works                   ║
║                                                                  ║
║  Remember: container must run with --privileged for perf!        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF

RUN echo 'cat ~/.welcome' >> /home/user/.bashrc

USER user
WORKDIR /home/user

CMD ["/bin/bash"]
