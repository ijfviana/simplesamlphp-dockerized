i#!/bin/bash

declare -A DIRS_TO_CHECK=(
  ["/var/simplesamlphp/config"]="/var/simplesamlphp-default/config"
  ["/var/simplesamlphp/metadata"]="/var/simplesamlphp-default/metadata"
  ["/var/simplesamlphp/modules"]="/var/simplesamlphp-default/modules"
  ["/var/simplesamlphp/cert"]="/var/simplesamlphp-default/cert"  # <-- Agregado cert
)

for TARGET_DIR in "${!DIRS_TO_CHECK[@]}"; do
  DEFAULT_DIR="${DIRS_TO_CHECK[$TARGET_DIR]}"

  if [ -d "$TARGET_DIR" ] && [ -z "$(ls -A "$TARGET_DIR")" ]; then
    echo "📂 '$TARGET_DIR' está vacío. Copiando desde '$DEFAULT_DIR'..."
    cp -rT "$DEFAULT_DIR" "$TARGET_DIR"
  fi
done

# Ejecutar el comando original del contenedor
exec "$@"
