from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=128)
    username_or_phone: str = Field(..., min_length=2, max_length=128)
    email: Optional[str] = None
    password: str = Field(..., min_length=4, max_length=128)

class UserLoginRequest(BaseModel):
    username_or_phone: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)

class PasswordResetRequest(BaseModel):
    contact: str = Field(..., min_length=3)

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    username_or_phone: str
    email: Optional[str] = None
    role: str = "patient"
    token: str
