FROM localstack/localstack:4.4

# Baked in (not bind-mounted): Shipyard only honors named volumes.
COPY --chmod=755 init-aws.sh /etc/localstack/init/ready.d/init-aws.sh
