# Simulator OpenFoam

### Installation

Build and run the container:

```bash
(cd keys && ./create_keys.sh)
docker-compose up
```

Connect via ssh (with various workarounds for possible authentication errors):

```bash
ssh -o IdentitiesOnly=yes \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -i keys/simulator_key \
    -p 10022 \
    testuser@localhost
```
