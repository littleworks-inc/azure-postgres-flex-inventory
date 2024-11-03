# azure-postgres-flex-inventory

A shell script to generate a comprehensive inventory of Azure Database for PostgreSQL Flexible Servers across all subscriptions. The script creates a detailed CSV report including server configurations, database listings, and storage metrics.

## Features

- Lists all PostgreSQL Flexible Servers across all Azure subscriptions
- Excludes system databases (azure_maintenance, postgres, azure_sys)
- Provides detailed server configurations including SKU and storage settings
- Includes current storage usage metrics in multiple units (Bytes, MB, GB)
- Exports data in CSV format for easy analysis in Excel

## Prerequisites

- Azure CLI installed and configured
- jq (JSON processor) installed
- bc (calculator) installed
- Active Azure subscription and appropriate permissions

### Installing Prerequisites

```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install azure-cli jq bc

# For macOS
brew install azure-cli jq

# For Windows
# Install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows
# Install jq from: https://stedolan.github.io/jq/download/
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/azure-postgres-flex-inventory.git
cd azure-postgres-flex-inventory
```

2. Make the script executable:
```bash
chmod +x list-postgres-servers.sh
```

## Usage

1. Run the script:
```bash
./list-postgres-servers.sh
```

2. The script will:
   - Check for prerequisites
   - Handle Azure login if needed
   - Process all subscriptions
   - Generate a timestamped CSV file in the current directory

## CSV Output Format

The generated CSV file includes the following columns:

| Column Name | Description |
|------------|-------------|
| Subscription | Azure Subscription ID |
| Resource Group | Resource Group name |
| Server Name | PostgreSQL Flexible Server name |
| PostgreSQL Version | Server PostgreSQL version |
| SKU Name | Server SKU (e.g., Standard_D4s_v3) |
| SKU Tier | Service tier (e.g., GeneralPurpose) |
| Storage Provisioned(GB) | Total storage allocated |
| IOPS | Provisioned IOPS |
| Storage Tier | Storage performance tier |
| Storage Type | Storage type configuration |
| Database Name | Name of each user database |
| Storage Used(Bytes) | Current storage usage in bytes |
| Storage Used(MB) | Current storage usage in megabytes |
| Storage Used(GB) | Current storage usage in gigabytes |

## Example Output

```csv
Subscription,Resource Group,Server Name,PostgreSQL Version,SKU Name,SKU Tier,Storage Provisioned(GB),IOPS,Storage Tier,Storage Type,Database Name,Storage Used(Bytes),Storage Used(MB),Storage Used(GB)
"sub-id-1","rg-postgres-prod","server1","14","Standard_D4s_v3","GeneralPurpose","1024","5000","P30","N/A","database1","222976573440","212741.12","207.75"
```

## Notes

- System databases (azure_maintenance, postgres, azure_sys) are excluded from the inventory
- Storage metrics are captured at the time of script execution
- Each database gets its own row in the CSV, sharing server-level information
- Empty database name indicates no user databases found on the server

## Limitations

- Requires appropriate Azure RBAC permissions to read server configurations and metrics
- Storage metrics might have slight delays based on Azure metrics availability
- Script execution time depends on the number of subscriptions and servers

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

Your Name (@your-github-username)

## Acknowledgments

- Azure CLI documentation
- Microsoft Azure PostgreSQL Flexible Server documentation
