from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

class PatientCreate(BaseModel):
    age: int = Field(..., ge=0, le=130)
    weight: float = Field(..., gt=0)
    bmi: Optional[float] = None
    gender: str = Field(..., min_length=1)
    known_disease: Optional[str] = ""
    allergies: Optional[str] = ""
    emergency_type: str = Field(..., min_length=1)

class PatientUpdate(BaseModel):
    age: Optional[int] = Field(None, ge=0, le=130)
    weight: Optional[float] = Field(None, gt=0)
    bmi: Optional[float] = None
    gender: Optional[str] = None
    known_disease: Optional[str] = None
    allergies: Optional[str] = None
    emergency_type: Optional[str] = None

class PatientResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    patient_id: str
    age: int
    weight: float
    bmi: Optional[float] = None
    gender: str
    known_disease: Optional[str] = ""
    allergies: Optional[str] = ""
    emergency_type: str
