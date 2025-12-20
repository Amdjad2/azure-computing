from azure.identity import AzureCliCredential
from azure.data.tables import TableServiceClient
import os

STORAGE_ACCOUNT_NAME = os.environ.get("STORAGE_ACCOUNT_NAME")
TABLE_NAME = os.environ.get("TABLE_NAME")

credential = AzureCliCredential()

table_service = TableServiceClient(
    endpoint=f"https://{STORAGE_ACCOUNT_NAME}.table.core.windows.net",
    credential=credential
)
table_client = table_service.get_table_client(TABLE_NAME)

entities = list(table_client.list_entities())
print("Nombre d'entités :", len(entities))
