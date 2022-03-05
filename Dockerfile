## Base layer (Ubuntu + Java + ca-certs)
FROM ubuntu:focal AS base
### Install Java + ca-certs
ENV JDK_VERSION=17
RUN set -xe \
    && apt-get update -q \
    && apt-get install -y -q ca-certificates openjdk-${JDK_VERSION}-jre-headless \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Build layer
### Will be composed of build tools (not needed in deployment layer) + source code
FROM base AS build
### Install clojure
### Does not change much => we do it a dedicated RUN to cache result
ENV CLOJURE_VERSION=1.10.3.1087
ENV CLOJURE_SHA256=fd3d465ac30095157ce754f1551b840008a6e3503ce5023d042d0490f7bafb98
RUN \
    apt-get update && \
    apt-get install -y curl make rlwrap && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://download.clojure.org/install/linux-install-${CLOJURE_VERSION}.sh --output linux-install-${CLOJURE_VERSION}.sh && \
    sha256sum linux-install-${CLOJURE_VERSION}.sh && \
    echo "${CLOJURE_SHA256} *linux-install-$CLOJURE_VERSION.sh" | sha256sum -c - && \
    chmod +x linux-install-$CLOJURE_VERSION.sh && \
    ./linux-install-${CLOJURE_VERSION}.sh && \
    rm linux-install-${CLOJURE_VERSION}.sh && \
    clojure -e "(clojure-version)"

WORKDIR /app

### Cache Clojure deps
#### "deps.edn" does not change regularly and is defining our dependencies
#### We COPY it and ask "clojure" to retrieve dependencies in
#### dedicated RUN so that Docker can cache results
#### That will speed up future "clojure" invocation to build/test our code
COPY deps.edn ./deps.edn
RUN clojure -P -M:uberdeps
#### Drawback is that test artifacts will be included into final image
RUN clojure -P -M:test

### Source code
#### Now that deps have been cached we COPY src/test folder that
#### are modified on a more regular basis
COPY src ./src

## Test layer
#### We use CMD => we will have to build image with specific "test" target
#### and docker run the generated image to run the tests
#### That allow us to run tests from CI in a dedicated step
FROM build AS test
COPY test ./test
CMD clojure -M:test -m kaocha.runner --skip-meta :integration

## Uberjar layer
### We build the artifacts in the "build" context/layer
FROM build AS uberjar
RUN clojure -M:uberdeps


## Deployment layer
### We copy the artifacts into base layer to lower the size of the final Docker image
FROM base AS deployment
COPY --from=uberjar /app/target/app.jar /app.jar
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
