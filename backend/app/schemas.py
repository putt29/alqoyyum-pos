"""Skema request (validasi di server)."""
import re
from typing import List, Optional

from pydantic import BaseModel, Field, field_validator

from . import config


class LoginIn(BaseModel):
    username: str = Field(min_length=1, max_length=60)
    password: str = Field(min_length=1, max_length=200)


class ChangePasswordIn(BaseModel):
    old_password: str = Field(min_length=1, max_length=200)
    new_password: str = Field(min_length=1, max_length=200)


class UserCreate(BaseModel):
    username: str
    full_name: str = Field(min_length=2, max_length=80)
    password: str = Field(min_length=1, max_length=200)

    @field_validator("username")
    @classmethod
    def _username(cls, v: str) -> str:
        v = v.strip()
        if not re.fullmatch(r"[A-Za-z0-9_.-]{3,30}", v):
            raise ValueError("Username 3-30 karakter (huruf, angka, titik, strip, garis bawah).")
        return v


class UserPatch(BaseModel):
    full_name: Optional[str] = Field(default=None, min_length=2, max_length=80)
    password: Optional[str] = Field(default=None, max_length=200)
    is_active: Optional[bool] = None


class ProductIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    category_id: int
    unit: Optional[str] = Field(default=None, max_length=20)
    cost_price: Optional[float] = Field(default=None, ge=0, le=10 ** 11)
    sale_price: int = Field(ge=0, le=10 ** 10)
    price_editable: bool = False
    icon_name: Optional[str] = None
    is_active: bool = True


class ProductPatch(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    category_id: Optional[int] = None
    unit: Optional[str] = Field(default=None, max_length=20)
    cost_price: Optional[float] = Field(default=None, ge=0, le=10 ** 11)
    sale_price: Optional[int] = Field(default=None, ge=0, le=10 ** 10)
    price_editable: Optional[bool] = None
    icon_name: Optional[str] = None
    is_active: Optional[bool] = None
    clear_unit: bool = False
    clear_cost: bool = False


class TxItemIn(BaseModel):
    product_id: int
    quantity: int = Field(ge=1, le=9999)
    unit_price: Optional[int] = Field(default=None, ge=0, le=10 ** 10)


class TxCreate(BaseModel):
    patient_name: str = Field(min_length=1, max_length=100)
    items: List[TxItemIn] = Field(min_length=1, max_length=config.MAX_ITEMS_PER_TX)
    payment_method: str = "Cash"
    payment: int = Field(ge=0, le=10 ** 11)


class TxDeleteIn(BaseModel):
    reason: str = Field(min_length=3, max_length=200)


class NumberingIn(BaseModel):
    next_sequence: int = Field(ge=1, le=10 ** 9)
