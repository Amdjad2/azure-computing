from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
# from azure.identity import AzureCliCredential
from azure.identity import DefaultAzureCredential
from azure.data.tables import TableServiceClient
import os
import uuid
from datetime import datetime

app = FastAPI(title="Azure Secure Web API")

# Variables d'environnement
STORAGE_ACCOUNT_NAME = os.environ.get("STORAGE_ACCOUNT_NAME", "azuresecurewebappdev")
TABLE_NAME = os.environ.get("TABLE_NAME", "messages")

# Credential pour local testing
# credential = AzureCliCredential()  

# DefaultAzureCredential() en prod App Service
credential = DefaultAzureCredential()

# Connexion Storage
table_service = TableServiceClient(
    endpoint=f"https://{STORAGE_ACCOUNT_NAME}.table.core.windows.net",
    credential=credential
)
table_client = table_service.get_table_client(TABLE_NAME)

# Modèle Pydantic pour POST
class Message(BaseModel):
    user: str
    text: str

# Endpoint health
@app.get("/health")
def health():
    return {"status": "ok"}

# Endpoint GET /messages
@app.get("/messages")
def get_messages():
    try:
        entities = list(table_client.list_entities())
        return entities
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Endpoint POST /messages
@app.post("/messages")
def create_message(message: Message):
    try:
        entity = {
            "PartitionKey": "messages",
            "RowKey": str(uuid.uuid4()),
            "user": message.user,
            "text": message.text,
            "timestamp": datetime.utcnow().isoformat()
        }
        table_client.create_entity(entity)
        return {"status": "created", "id": entity["RowKey"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
