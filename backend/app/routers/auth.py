from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserRegisterRequest, UserLoginRequest, PasswordResetRequest, UserResponse
from app.services.auth_service import AuthService
from app.core.security import get_current_user_token
from app.models.user import User
from fastapi import HTTPException, status

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    """Register a new user account."""
    return AuthService.register_user(db, req)

@router.post("/login", response_model=UserResponse)
def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    """Authenticate with username or phone and password."""
    return AuthService.login_user(db, req)

@router.post("/reset-password")
def reset_password(req: PasswordResetRequest, db: Session = Depends(get_db)):
    """Request password reset instructions."""
    return AuthService.reset_password(db, req.contact)

@router.get("/me")
def get_current_user(token_data: dict = Depends(get_current_user_token), db: Session = Depends(get_db)):
    """Get profile of currently authenticated user."""
    if not token_data or "sub" not in token_data:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    user = db.query(User).filter(User.id == token_data["sub"]).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return {
        "id": user.id,
        "name": user.name,
        "username_or_phone": user.username_or_phone,
        "email": user.email,
        "role": user.role
    }
