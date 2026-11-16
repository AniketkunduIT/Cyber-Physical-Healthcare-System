import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.emergency import EmergencyRequest, Hospital
from app.schemas.emergency import AmbulanceRequest, AmbulanceResponse, HospitalResponse

class EmergencyService:
    @staticmethod
    def request_ambulance(
        db: Session,
        req: AmbulanceRequest,
        user_id: Optional[str] = "user_001"
    ) -> AmbulanceResponse:
        emergency_request = EmergencyRequest(
            id=f"emg_{uuid.uuid4().hex[:12]}",
            user_id=user_id,
            latitude=req.latitude,
            longitude=req.longitude,
            emergency_type_id=req.emergencyTypeId,
            status="assigned",
            driver_name="Rakesh Sharma",
            vehicle_number="KA 01 EM 1234",
            eta_minutes=7,
            equipment="Oxygen, Ventilator, ICU support",
            driver_phone="+919876543210",
            medical_team_phone="+919812345678"
        )
        db.add(emergency_request)
        db.commit()
        db.refresh(emergency_request)

        equipment_list = [e.strip() for e in emergency_request.equipment.split(",") if e.strip()]

        return AmbulanceResponse(
            driverName=emergency_request.driver_name,
            vehicleNumber=emergency_request.vehicle_number,
            etaMinutes=emergency_request.eta_minutes,
            equipment=equipment_list,
            driverPhone=emergency_request.driver_phone,
            medicalTeamPhone=emergency_request.medical_team_phone
        )

    @staticmethod
    def get_nearby_hospitals(db: Session) -> List[HospitalResponse]:
        hospitals = db.query(Hospital).all()
        return [
            HospitalResponse(
                id=h.id,
                name=h.name,
                address=h.address,
                distanceKm=h.distance_km,
                phone=h.phone,
                hasEmergencyBeds=h.has_emergency_beds
            )
            for h in hospitals
        ]
