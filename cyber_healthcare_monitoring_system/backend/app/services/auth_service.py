import uuid
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import User
from app.models.medical_record import MedicalProfile
from app.schemas.user import UserRegisterRequest, UserLoginRequest, UserResponse
from app.core.security import hash_password, verify_password, create_access_token

class AuthService:
    @staticmethod
    def register_user(db: Session, req: UserRegisterRequest) -> UserResponse:
        existing = db.query(User).filter(
            (User.username_or_phone == req.username_or_phone) |
            (User.email == req.email if req.email else False)
        ).first()

        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A user with this username, phone, or email already exists."
            )

        user_id = f"user_{uuid.uuid4().hex[:8]}"
        hashed_pwd = hash_password(req.password)

        new_user = User(
            id=user_id,
            name=req.name.strip(),
            username_or_phone=req.username_or_phone.strip(),
            email=req.email.strip() if req.email else None,
            hashed_password=hashed_pwd,
            role="patient"
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        # Create blank profile for new user
        new_profile = MedicalProfile(
            id=f"mp_{user_id}",
            user_id=user_id,
            known_diseases="",
            allergies=""
        )
        db.add(new_profile)
        db.commit()

        token = create_access_token({"sub": new_user.id, "name": new_user.name, "role": new_user.role})

        return UserResponse(
            id=new_user.id,
            name=new_user.name,
            username_or_phone=new_user.username_or_phone,
            email=new_user.email,
            role=new_user.role,
            token=token
        )

    @staticmethod
    def login_user(db: Session, req: UserLoginRequest) -> UserResponse:
        user = db.query(User).filter(
            (User.username_or_phone == req.username_or_phone) |
            (User.email == req.username_or_phone)
        ).first()

        if not user or not verify_password(req.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password. Please try again."
            )

        token = create_access_token({"sub": user.id, "name": user.name, "role": user.role})

        return UserResponse(
            id=user.id,
            name=user.name,
            username_or_phone=user.username_or_phone,
            email=user.email,
            role=user.role,
            token=token
        )

    @staticmethod
    def reset_password(db: Session, contact: str) -> dict:
        contact_clean = contact.strip()
        user = db.query(User).filter(
            (User.username_or_phone == contact_clean) |
            (User.email == contact_clean)
        ).first()

        if not user:
            # For security, avoid enumerating accounts, or return message
            return {"message": f"If an account is associated with '{contact_clean}', a reset link has been dispatched."}

        return {"message": f"Password reset instructions have been sent to {contact_clean}."}
