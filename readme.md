# Simulator OpenFoam

### Installation

Build and run the container:

```bash
(cd keys && ./create_keys.sh)
docker-compose up
```

Connect via ssh (with various workarounds for possible authentication errors):

```bash
ssh -o StrictHostKeyChecking=no -i keys/simulator_key testuser@0.0.0.0 -p 10022
```
