# syntax=docker/dockerfile:1.7-labs
FROM python:3.10-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    BITCAST_HOME=/opt/bitcast

WORKDIR ${BITCAST_HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./requirements.txt
RUN python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY . .
COPY entrypoint.sh /usr/local/bin/bitcast-entrypoint
RUN chmod +x /usr/local/bin/bitcast-entrypoint

ARG BITCAST_ROLE=validator
ENV BITCAST_ROLE=${BITCAST_ROLE}

ENTRYPOINT ["/usr/local/bin/bitcast-entrypoint"]
