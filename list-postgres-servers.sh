#!/bin/bash

# Function to check if Azure CLI is installed
check_az_cli() {
    if ! command -v az &> /dev/null; then
        echo "Error: Azure CLI is not installed. Please install it first."
        echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
}

# Function to handle Azure login
azure_login() {
    echo "Checking Azure login status..."
    
    # Check if already logged in
    if ! az account show &> /dev/null; then
        echo "Not logged in. Initiating Azure login..."
        if ! az login; then
            echo "Error: Azure login failed"
            exit 1
        fi
        echo "Login successful!"
    else
        echo "Already logged into Azure"
        current_account=$(az account show --query user.name -o tsv)
        echo "Current account: $current_account"
    fi
}

# Function to get storage metrics for a server
get_storage_metrics() {
    local subscription=$1
    local resource_group=$2
    local server_name=$3
    
    # Construct resource ID
    local resource_id="/subscriptions/$subscription/resourceGroups/$resource_group/providers/Microsoft.DBforPostgreSQL/flexibleServers/$server_name"
    
    # Get storage metrics
    metrics=$(az monitor metrics list \
        --resource "$resource_id" \
        --metric storage_used \
        --aggregation Maximum \
        --query 'value[0].timeseries[0].data[0].maximum' \
        -o tsv 2>/dev/null || echo "0")
    
    echo "$metrics"
}

# Function to convert bytes to MB and GB
convert_storage_size() {
    local bytes=$1
    local mb=$(echo "scale=2; $bytes / 1024 / 1024" | bc)
    local gb=$(echo "scale=2; $bytes / 1024 / 1024 / 1024" | bc)
    echo "$bytes|$mb|$gb"
}

# Function to get databases for a specific server
get_databases() {
    local server_name=$1
    local resource_group=$2
    
    # Get all databases except system databases
    databases=$(az postgres flexible-server db list \
        --resource-group "$resource_group" \
        --server-name "$server_name" \
        --query '[].name' \
        -o tsv | grep -v -E '^(azure_maintenance|postgres|azure_sys)$' || echo "")
    
    echo "$databases"
}

# Function to create and initialize CSV file
create_csv_file() {
    local output_file="postgres_inventory_$(date '+%Y%m%d_%H%M%S').csv"
    echo "Subscription,Resource Group,Server Name,PostgreSQL Version,SKU Name,SKU Tier,Storage Provisioned(GB),IOPS,Storage Tier,Storage Type,Database Name,Storage Used(Bytes),Storage Used(MB),Storage Used(GB)" > "$output_file"
    echo "$output_file"
}

# Function to list PostgreSQL Flexible Servers across all subscriptions
list_postgres_flex_servers() {
    echo "Creating PostgreSQL servers inventory..."
    
    # Create CSV file and get filename
    csv_file=$(create_csv_file)
    
    # Get all subscriptions
    subscriptions=$(az account list --query "[].{SubscriptionId:id,Name:name}" -o json)
    
    # Loop through each subscription
    echo "$subscriptions" | jq -c '.[]' | while read -r sub; do
        sub_id=$(echo "$sub" | jq -r '.SubscriptionId')
        
        echo "Processing subscription: $sub_id"
        
        # Set the current subscription
        az account set --subscription "$sub_id" >/dev/null 2>&1
        
        # List all PostgreSQL Flexible Servers in the subscription with detailed info
        servers=$(az postgres flexible-server list \
            --query '[].{name:name,resourceGroup:resourceGroup,version:version,skuName:sku.name,skuTier:sku.tier,storageSizeGb:storage.storageSizeGb,storageIOPS:storage.iops,storageTier:storage.tier,storageType:storage.type}' \
            -o json)
        
        # Check if any servers were found
        if [ "$(echo "$servers" | jq length)" -gt 0 ]; then
            echo "$servers" | jq -c '.[]' | while read -r server; do
                server_name=$(echo "$server" | jq -r '.name')
                resource_group=$(echo "$server" | jq -r '.resourceGroup')
                version=$(echo "$server" | jq -r '.version')
                sku_name=$(echo "$server" | jq -r '.skuName')
                sku_tier=$(echo "$server" | jq -r '.skuTier')
                storage_gb=$(echo "$server" | jq -r '.storageSizeGb')
                storage_iops=$(echo "$server" | jq -r '.storageIOPS')
                storage_tier=$(echo "$server" | jq -r '.storageTier')
                storage_type=$(echo "$server" | jq -r '.storageType')
                
                # Get storage metrics
                storage_used=$(get_storage_metrics "$sub_id" "$resource_group" "$server_name")
                storage_converted=$(convert_storage_size "$storage_used")
                storage_bytes=$(echo "$storage_converted" | cut -d'|' -f1)
                storage_mb=$(echo "$storage_converted" | cut -d'|' -f2)
                storage_gb=$(echo "$storage_converted" | cut -d'|' -f3)
                
                # Get databases for this server (excluding system databases)
                databases=$(get_databases "$server_name" "$resource_group")
                
                if [ -n "$databases" ]; then
                    # Create a row for each database
                    echo "$databases" | while read -r db_name; do
                        echo "\"$sub_id\",\"$resource_group\",\"$server_name\",\"$version\",\"$sku_name\",\"$sku_tier\",\"$storage_gb\",\"$storage_iops\",\"$storage_tier\",\"${storage_type:-N/A}\",\"$db_name\",\"$storage_bytes\",\"$storage_mb\",\"$storage_gb\"" >> "$csv_file"
                    done
                else
                    # If no user databases found, create one row with empty database name
                    echo "\"$sub_id\",\"$resource_group\",\"$server_name\",\"$version\",\"$sku_name\",\"$sku_tier\",\"$storage_gb\",\"$storage_iops\",\"$storage_tier\",\"${storage_type:-N/A}\",\"\",\"$storage_bytes\",\"$storage_mb\",\"$storage_gb\"" >> "$csv_file"
                fi
            done
        fi
    done
    
    echo -e "\nInventory CSV file has been created: $csv_file"
}

# Main execution flow
echo "=== Azure PostgreSQL Flexible Servers Inventory Script ==="
echo "Checking prerequisites..."

# Check if Azure CLI is installed
check_az_cli

# Perform Azure login
azure_login

# Execute the main function
list_postgres_flex_servers
