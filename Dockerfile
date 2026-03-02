FROM ubuntu:24.04

ARG LOVE_VERSION=11.5
ARG GAME_NAME=game

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        zip \
        unzip \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and cache Love2D binaries for all platforms
RUN mkdir -p /opt/love/win64 /opt/love/macos /opt/love/linux && \
    LOVE_URL="https://github.com/love2d/love/releases/download/${LOVE_VERSION}" && \
    # Windows 64-bit
    curl -fsSL "${LOVE_URL}/love-${LOVE_VERSION}-win64.zip" -o /tmp/love-win64.zip && \
    unzip -q /tmp/love-win64.zip -d /tmp/love-win64 && \
    mv /tmp/love-win64/love-${LOVE_VERSION}-win64/* /opt/love/win64/ && \
    rm -rf /tmp/love-win64 /tmp/love-win64.zip && \
    # macOS
    curl -fsSL "${LOVE_URL}/love-${LOVE_VERSION}-macos.zip" -o /tmp/love-macos.zip && \
    unzip -q /tmp/love-macos.zip -d /tmp/love-macos && \
    mv /tmp/love-macos/love.app /opt/love/macos/love.app && \
    rm -rf /tmp/love-macos /tmp/love-macos.zip && \
    # Linux AppImage
    curl -fsSL "${LOVE_URL}/love-${LOVE_VERSION}-x86_64.AppImage" \
        -o /opt/love/linux/love-${LOVE_VERSION}-x86_64.AppImage && \
    chmod +x /opt/love/linux/love-${LOVE_VERSION}-x86_64.AppImage

WORKDIR /game

COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

CMD ["build.sh"]
