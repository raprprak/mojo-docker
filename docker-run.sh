docker run \
    -it \
    -v ../:/workspace \
    --network=host \
    --name=mojo \
    mojosdk:1.0