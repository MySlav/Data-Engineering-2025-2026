# --- adjust these ---
$Csv      = "C:\Users\Mislav\fsi.csv"   # your CSV on Windows
$PodName  = "postgres-pgadmin-pod-postgres"       # actual container name


podman exec -it $PodName bash -lc "mkdir -p /var/lib/postgresql/import && chown -R postgres:postgres /var/lib/postgresql/import"

podman cp $Csv "${PodName}:/var/lib/postgresql/import/fsi.csv"
# rights
podman exec -it $PodName bash -lc "chmod 644 /var/lib/postgresql/import/fsi.csv"