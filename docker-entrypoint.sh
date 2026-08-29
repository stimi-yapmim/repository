#!/bin/bash
set -e

# Default environment variables
EPRINTS_REPO_ID=${EPRINTS_REPO_ID:-"myrepo"}
EPRINTS_HOSTNAME=${EPRINTS_HOSTNAME:-"localhost"}
DB_HOST=${DB_HOST:-"db"}

# Wait for DB to be ready
echo "Waiting for database at $DB_HOST..."
while ! mysqladmin ping -h"$DB_HOST" -u"root" -p"${MYSQL_ROOT_PASSWORD}" --silent; do
    sleep 2
done
echo "Database is ready!"

# Check if an EPrints repository exists
if [ ! -d "/opt/eprints3/archives/$EPRINTS_REPO_ID" ]; then
    echo "=========================================================================="
    echo "WARNING: No EPrints repository configured."
    echo "To create one, open a new terminal and run the following command:"
    echo "docker compose exec -u eprints web /opt/eprints3/bin/epadmin create"
    echo ""
    echo "After creation, you may need to restart the web container."
    echo "=========================================================================="
    
    # Generate empty system apache config just to allow Apache to start
    su - eprints -c "/opt/eprints3/bin/generate_apacheconf --system"
    # Create a dummy config to prevent Apache from failing due to empty Include wildcard
    mkdir -p /opt/eprints3/cfg/apache
    touch /opt/eprints3/cfg/apache/dummy.conf
    chown -R eprints:eprints /opt/eprints3/cfg/apache
else
    echo "Found repository: $EPRINTS_REPO_ID"
    # Regenerate config to ensure it matches current container environment
    su - eprints -c "/opt/eprints3/bin/generate_apacheconf --system"
    su - eprints -c "/opt/eprints3/bin/generate_apacheconf"
    
    # Ensure permissions are correct on the archives volume
    chown -R eprints:eprints /opt/eprints3/archives
fi

# Ensure log directory exists and has correct permissions
mkdir -p /var/log/apache2
chown -R root:adm /var/log/apache2

echo "Starting Apache..."
exec "$@"
