# syntax=docker/dockerfile:1.7

# --- Stage 1: build the static dist/ with Lua + LuaFileSystem ---
FROM alpine:3.20 AS builder
RUN apk add --no-cache lua5.4 lua5.4-filesystem
WORKDIR /src

# Copy the whole repo; build-index needs lessons/, shared/, and the tool.
COPY . .

# Render the landing page + copy decks + vendored reveal.js into /dist.
RUN lua5.4 tools/build-index/main.lua \
    --lessons /src/lessons \
    --shared /src/shared/reveal \
    --out /dist

# --- Stage 2: serve dist/ with non-root nginx ---
FROM nginxinc/nginx-unprivileged:alpine
USER root
COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /dist /usr/share/nginx/html
# Drop back to the unprivileged user the image ships with (UID 101).
USER 101
EXPOSE 8080
