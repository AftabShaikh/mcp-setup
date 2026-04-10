"""List Azure resource groups in the Connectivity subscription."""

from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient

TENANT_ID = "717270cf-789f-40e0-87a5-bc9d057c85fd"
SUBSCRIPTION_ID = "8086c527-cc16-4ef8-9d45-6a8ff4849350"


def list_resource_groups():
    credential = DefaultAzureCredential(
        additionally_allowed_tenants=[TENANT_ID]
    )
    client = ResourceManagementClient(credential, SUBSCRIPTION_ID)

    print(f"{'Resource Group':<50} {'Location':<20}")
    print("-" * 70)

    for rg in client.resource_groups.list():
        print(f"{rg.name:<50} {rg.location:<20}")


if __name__ == "__main__":
    list_resource_groups()
