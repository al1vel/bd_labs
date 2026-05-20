from pydantic import BaseModel, ConfigDict, Field
from decimal import Decimal
from typing import Literal

class UserBase(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., min_length=3, max_length=100)
    phone: str | None = Field(None, max_length=20)


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    full_name: str | None = Field(None, min_length=1, max_length=100)
    email: str | None = Field(None, min_length=3, max_length=100)
    phone: str | None = Field(None, max_length=20)


class UserRead(UserBase):
    model_config = ConfigDict(from_attributes=True)

    user_id: int


class SupplierBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    supplier_type: Literal["store", "farmer"]


class SupplierCreate(SupplierBase):
    pass


class SupplierUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=150)
    supplier_type: Literal["store", "farmer"] | None = None


class SupplierRead(SupplierBase):
    model_config = ConfigDict(from_attributes=True)

    supplier_id: int


class ProductBase(BaseModel):
    supplier_id: int
    name: str = Field(..., min_length=1, max_length=150)
    description: str | None = None
    price: Decimal = Field(..., gt=0)
    is_active: bool | None = True


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    supplier_id: int | None = None
    name: str | None = Field(None, min_length=1, max_length=150)
    description: str | None = None
    price: Decimal | None = Field(None, gt=0)
    is_active: bool | None = None


class ProductRead(ProductBase):
    model_config = ConfigDict(from_attributes=True)

    product_id: int


class GroupOrderBase(BaseModel):
    supplier_id: int
    title: str = Field(..., min_length=1, max_length=150)
    description: str | None = None
    status: str = Field("open", max_length=20)
    min_participants: int | None = Field(None, ge=1)
    min_total_amount: Decimal | None = Field(None, ge=0)


class GroupOrderCreate(GroupOrderBase):
    pass


class GroupOrderUpdate(BaseModel):
    supplier_id: int | None = None
    title: str | None = Field(None, min_length=1, max_length=150)
    description: str | None = None
    status: str | None = Field(None, max_length=20)
    min_participants: int | None = Field(None, ge=1)
    min_total_amount: Decimal | None = Field(None, ge=0)


class GroupOrderRead(GroupOrderBase):
    model_config = ConfigDict(from_attributes=True)

    group_order_id: int


class JoinGroupOrderRequest(BaseModel):
    user_id: int
    participation_role: Literal["participant", "organizer"] = "participant"


class AddOrderItemRequest(BaseModel):
    participation_id: int
    product_id: int
    quantity: Decimal = Field(..., gt=0)