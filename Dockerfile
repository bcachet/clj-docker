FROM openjdk:17-buster AS base

## Build layer
FROM base AS build
# clojure
ENV CLOJURE_VERSION=1.10.3.1087
RUN \
    apt-get update && \
    apt-get install -y make rlwrap && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://download.clojure.org/install/linux-install-$CLOJURE_VERSION.sh && \
    sha256sum linux-install-$CLOJURE_VERSION.sh && \
    echo "fd3d465ac30095157ce754f1551b840008a6e3503ce5023d042d0490f7bafb98 *linux-install-$CLOJURE_VERSION.sh" | sha256sum -c - && \
    chmod +x linux-install-$CLOJURE_VERSION.sh && \
    ./linux-install-$CLOJURE_VERSION.sh && \
    rm linux-install-$CLOJURE_VERSION.sh && \
    clojure -e "(clojure-version)"

WORKDIR /app
COPY src ./src
COPY test ./test
COPY deps.edn ./deps.edn

RUN ["clj", "-M:uberdeps"]

## Test layer
FROM build AS test
RUN ["clj", "-M:test"]

## Deployment layer
FROM base AS deployment
COPY --from=build /app/target/app.jar /app.jar
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
