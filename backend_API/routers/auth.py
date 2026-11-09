from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Usuario
from schemas import UsuarioRegistro, UsuarioLogin, Token, UsuarioOut
from auth import hash_password, verificar_password, crear_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Autenticacion"])


@router.post("/registrar", response_model=Token, status_code=201)
def registrar(datos: UsuarioRegistro, db: Session = Depends(get_db)):
    existe = db.query(Usuario).filter(Usuario.mail == datos.mail).first()

    if existe:
        raise HTTPException(status_code=400, detail="El correo ya esta registrado")

    if len(datos.password) < 8:
        raise HTTPException(
            status_code=400,
            detail="La contrasena debe tener al menos 8 caracteres"
        )

    usuario = Usuario(
        nom_usr=datos.nom_usr,
        mail=datos.mail,
        password_hash=hash_password(datos.password),
        tip_usu=1,
        estatus=1
    )

    db.add(usuario)
    db.commit()
    db.refresh(usuario)

    token = crear_token({"sub": str(usuario.id_usr)})

    return Token(
        access_token=token,
        usuario=UsuarioOut.from_orm(usuario)
    )


@router.post("/login", response_model=Token)
def login(datos: UsuarioLogin, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.mail == datos.mail).first()

    if not usuario or not verificar_password(datos.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contrasena incorrectos"
        )

    if usuario.estatus == 0:
        raise HTTPException(status_code=403, detail="Cuenta suspendida")

    token = crear_token({"sub": str(usuario.id_usr)})

    return Token(access_token=token, usuario=UsuarioOut.from_orm(usuario))


@router.get("/me", response_model=UsuarioOut)
def me(usuario: Usuario = Depends(get_current_user)):
    return usuario
