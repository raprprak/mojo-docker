docker build --no-cache \
    --build-arg AUTH_KEY=DEFAULT_KEY \
    -t mojosdk:1.0 \
    -f Dockerfile