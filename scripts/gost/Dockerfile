# 轻量 Alpine + gost HTTP 代理
# 构建: docker compose build
# 运行: docker compose up -d

ARG GOST_VERSION=3.0.0-rc10
FROM alpine:3.20

ARG GOST_VERSION
ARG TARGETARCH

RUN apk add --no-cache ca-certificates curl tzdata \
	&& ARCH="${TARGETARCH:-amd64}" \
	&& case "${ARCH}" in \
		amd64|x86_64) ARCH=amd64 ;; \
		arm64|aarch64) ARCH=arm64 ;; \
		arm|arm/v7) ARCH=armv7 ;; \
		*) echo "unsupported arch: ${ARCH}" && exit 1 ;; \
	esac \
	&& curl -fsSL -o /tmp/gost.tar.gz \
		"https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${ARCH}.tar.gz" \
	&& tar -xzf /tmp/gost.tar.gz -C /usr/local/bin gost \
	&& chmod +x /usr/local/bin/gost \
	&& rm -f /tmp/gost.tar.gz \
	&& apk del curl

ENV GOST_USER=checkin \
	GOST_PASS= \
	GOST_PORT=7890 \
	TZ=Asia/Shanghai

EXPOSE 7890

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
