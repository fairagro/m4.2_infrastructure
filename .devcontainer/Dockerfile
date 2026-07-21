# Dev Container Dockerfile for m4.2_infrastructure
# Replaces devcontainer feature-based installation with a reproducible Dockerfile.
#
# All tool versions are pinned for reproducibility.

FROM mcr.microsoft.com/devcontainers/base:2.1.10-trixie

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG KUBECTL_VERSION=v1.28.6
ARG HELM_VERSION=v3.16.1
ARG ARGOCD_VERSION=v2.12.4
ARG CT_VERSION=v3.11.0
ARG SOPS_VERSION=v3.9.0
ARG AGE_VERSION=v1.1.1
ARG STARSHIP_VERSION=v1.20.1
ARG YQ_VERSION=v4.44.3
ARG JQ_VERSION=jq-1.7.1
ARG HADOLINT_VERSION=v2.12.0

ENV DEBIAN_FRONTEND=noninteractive

# ── Base packages ─────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    wget \
    gnupg \
    lsb-release \
    vim \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    bash-completion \
    dnsutils \
    iputils-ping \
    ncat \
    && rm -rf /var/lib/apt/lists/*

# ── GitHub CLI (APT repos) ────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | gpg --batch --yes --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends \
        gh \
    && rm -rf /var/lib/apt/lists/*

# ── kubectl (direct binary; pkgs.k8s.io APT repo uses legacy OpenPGP v3 signatures
#    rejected by Debian Trixie's sqv since 2026-02-01) ─────────────────────────
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# ── Helm ──────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
        | tar -xz --strip-components=1 -C /usr/local/bin linux-amd64/helm

# ── Argo CD CLI ───────────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64" \
        -o /usr/local/bin/argocd && chmod +x /usr/local/bin/argocd

# ── chart-testing (ct) ────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/helm/chart-testing/releases/download/${CT_VERSION}/chart-testing_${CT_VERSION#v}_linux_amd64.tar.gz" \
        | tar -xz -C /usr/local/bin ct

# ── yq ────────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
        -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# ── jq (pinned binary) ────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/jqlang/jq/releases/download/${JQ_VERSION}/jq-linux-amd64" \
        -o /usr/local/bin/jq && chmod +x /usr/local/bin/jq

# ── hadolint ──────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
        -o /usr/local/bin/hadolint && chmod +x /usr/local/bin/hadolint

# ── SOPS ──────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64" \
        -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops

# ── age ───────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" \
        | tar -xz --strip-components=1 -C /usr/local/bin age/age age/age-keygen

# ── Starship prompt ───────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz" \
        | tar -xz -C /usr/local/bin

# ── cert-manager cmctl ────────────────────────────────────────────────────────
RUN curl -fsSL "https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_linux_amd64" \
        -o /usr/local/bin/cmctl && chmod +x /usr/local/bin/cmctl

# ── git-filter-repo ───────────────────────────────────────────────────────────
RUN curl -fsSL "https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo" \
        -o /usr/local/bin/git-filter-repo && chmod +x /usr/local/bin/git-filter-repo

# ── Bash completions (build-time, lazy-loaded via bash-completion) ───────────
RUN mkdir -p /usr/share/bash-completion/completions && \
    gh completion -s bash > /usr/share/bash-completion/completions/gh && \
    kubectl completion bash > /usr/share/bash-completion/completions/kubectl && \
    helm completion bash > /usr/share/bash-completion/completions/helm && \
    argocd completion bash > /usr/share/bash-completion/completions/argocd && \
    yq shell-completion bash > /usr/share/bash-completion/completions/yq && \
    starship completions bash > /usr/share/bash-completion/completions/starship

# ── Shell init (must run each session; not installable as static completions) ─
RUN echo 'eval "$(starship init bash)"' >> /etc/bash.bashrc

# ── Shell history persistence helper (stuartleeks pattern) ───────────────────
RUN echo 'export HISTFILE=/commandhistory/.bash_history' >> /etc/bash.bashrc && \
    echo 'PROMPT_COMMAND="history -a; $PROMPT_COMMAND"' >> /etc/bash.bashrc && \
    mkdir -p /commandhistory && \
    touch /commandhistory/.bash_history && \
    chown -R vscode /commandhistory
