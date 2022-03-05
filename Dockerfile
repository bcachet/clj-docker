FROM openjdk:17-buster AS base

## Build layer
### Will be composed of build tools + source code
FROM base AS build
### Install clojure
### Does not change much => we do it a dedicated RUN to cache result
ENV CLOJURE_VERSION=1.10.3.1087
ENV CLOJURE_SHA256=fd3d465ac30095157ce754f1551b840008a6e3503ce5023d042d0490f7bafb98
RUN \
    apt-get update && \
    apt-get install -y make rlwrap && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://download.clojure.org/install/linux-install-${CLOJURE_VERSION}.sh && \
    sha256sum linux-install-${CLOJURE_VERSION}.sh && \
    echo "${CLOJURE_SHA256} *linux-install-$CLOJURE_VERSION.sh" | sha256sum -c - && \
    chmod +x linux-install-$CLOJURE_VERSION.sh && \
    ./linux-install-${CLOJURE_VERSION}.sh && \
    rm linux-install-${CLOJURE_VERSION}.sh && \
    clojure -e "(clojure-version)"

WORKDIR /app

### Cache Clojure deps
#### Retrieving depends only on "deps.edn" file that we do not change so often
#### We retrieve deps from a dedicated RUN to cache the result
#### That will speed up later usage of "clojure" command in later CMD/RUN
COPY deps.edn ./deps.edn
RUN clojure -P -M:uberdeps
RUN clojure -P -M:test

### Source code
#### Now that deps have been cached we COPY src/test folder that
#### are modified on a more regular basis
COPY src ./src
COPY test ./test

## Test layer
#### We use CMD => we will have to build image with specific "test" target
#### and docker run the generated image to run the tests
#### That allow us to run tests from CI in a dedicated step
FROM build AS test
CMD clojure -M:test -m kaocha.runner

## Uberjar layer
### We build the artifacts in the "build" context/layer
FROM build AS uberjar
RUN clojure -M:uberdeps

## Deployment layer
### We copy the artifacts in a smaller image to lower the size of the final Docker image
FROM base AS deployment
COPY --from=uberjar /app/target/app.jar /app.jar
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
