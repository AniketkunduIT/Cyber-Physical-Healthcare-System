from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict

class AmbulanceRequest(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    emergencyTypeId: str = Field(..., min_length=1)

class AmbulanceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    driverName: str
    vehicleNumber: str
    etaMinutes: int
    equipment: List[str]
    driverPhone: str
    medicalTeamPhone: str

class HospitalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    address: str
    distanceKm: float
    phone: str
    hasEmergencyBeds: bool
