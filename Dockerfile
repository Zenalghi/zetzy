# Multi-stage Dockerfile for building Zetzy Web directly from source.
# Example:
#   docker build \
#     --build-arg SUPABASE_URL=https://your-project.supabase.co \
#     --build-arg SUPABASE_ANON_KEY=your-anon-key \
#     -t zetzy-web .

FROM ghcr.io/cirruslabs/flutter:stable AS builder

ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""

WORKDIR /app
COPY pubspec.yaml pubspec.lock l10n.yaml ./
RUN flutter pub get

COPY . .
RUN flutter gen-l10n && \
    flutter build web --release \
      --base-href "/" \
      --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
      --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

FROM nginx:1.27-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
