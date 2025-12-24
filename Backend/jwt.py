from jose import jwt
from datetime import datetime, timedelta
SECRET_KEY = "leducvu_192005"
ALGORITHM = "HS256"
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expires =datetime.utcnow() + timedelta(hours=2)
    to_encode.update({"exp": expires})
    return jwt.encode(to_encode, SECRET_KEY, algorithm = ALGORITHM)