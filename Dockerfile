FROM node:lts-alpine3.20

ARG BUILD_DATE
ARG VERSION="1.0"

LABEL maintainer="VaronaTech"
LABEL build_version="Nginx version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL org.opencontainers.image.authors="HL Varona <humberto.varona@gmail.com>"
LABEL org.opencontainers.image.description="EJS: Expres.js container optimized"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

WORKDIR /usr/src/app

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

RUN apk add --no-cache curl sqlite sqlite-libs jq nano \
    && printf "EJS version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version \
    && rm -rf /var/cache/apk/* /tmp/*  

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["start.sh"]
