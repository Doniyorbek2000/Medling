# MedLink API — ishlab chiqarish uchun image.
# Yig'ish:  docker build -t medlink-backend backend
ARG DART_VERSION=3.13.7

FROM dart:${DART_VERSION} AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY . .
RUN dart pub get --offline && dart compile exe bin/server.dart -o bin/server

# Minimal runtime: faqat AOT binar, Dart runtime kutubxonalari va
# CA sertifikatlari (Vertex AI, FCM, Eskiz, Stripe'ga HTTPS uchun).
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /etc/ssl/certs /etc/ssl/certs
COPY --from=build /app/bin/server /app/bin/server
# root bo'lmagan foydalanuvchi
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
