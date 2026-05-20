import os
from decimal import Decimal

from sqlalchemy import (
    MetaData,
    String,
    Text,
    ForeignKey,
    Integer,
    Boolean,
    Numeric,
    CheckConstraint,
    UniqueConstraint,
    Index,
)
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_async_engine(DATABASE_URL)
async_session = async_sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
metadata = MetaData()

async def get_db():
    async with async_session() as session:
        yield session

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"

    user_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)

    participations: Mapped[list["Participation"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )


class Supplier(Base):
    __tablename__ = "suppliers"

    supplier_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    supplier_type: Mapped[str] = mapped_column(String(20), nullable=False)

    products: Mapped[list["Product"]] = relationship(
        back_populates="supplier",
        cascade="all, delete-orphan",
    )

    group_orders: Mapped[list["GroupOrder"]] = relationship(
        back_populates="supplier",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        CheckConstraint(
            "supplier_type IN ('store', 'farmer')",
            name="check_supplier_type",
        ),
    )


class Product(Base):
    __tablename__ = "products"

    product_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    supplier_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("suppliers.supplier_id", ondelete="CASCADE"),
        nullable=False,
    )

    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=True)

    supplier: Mapped["Supplier"] = relationship(back_populates="products")

    order_items: Mapped[list["OrderItem"]] = relationship(
        back_populates="product",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        CheckConstraint("price > 0", name="check_product_price_positive"),
    )


class GroupOrder(Base):
    __tablename__ = "group_orders"

    group_order_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    supplier_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("suppliers.supplier_id", ondelete="CASCADE"),
        nullable=False,
    )

    title: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[str] = mapped_column(String(20), nullable=False, default="open")

    min_participants: Mapped[int | None] = mapped_column(Integer, nullable=True)
    min_total_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)

    supplier: Mapped["Supplier"] = relationship(back_populates="group_orders")

    participations: Mapped[list["Participation"]] = relationship(
        back_populates="group_order",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        CheckConstraint("min_participants >= 1", name="check_min_participants"),
        CheckConstraint("min_total_amount >= 0", name="check_min_total_amount"),
    )


class Participation(Base):
    __tablename__ = "participations"

    participation_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    group_order_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("group_orders.group_order_id", ondelete="CASCADE"),
        nullable=False,
    )

    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )

    participant_status: Mapped[str | None] = mapped_column(
        String(20),
        default="joined",
        nullable=True,
    )

    participation_role: Mapped[str] = mapped_column(
        String(20),
        default="participant",
        nullable=False,
    )

    group_order: Mapped["GroupOrder"] = relationship(back_populates="participations")
    user: Mapped["User"] = relationship(back_populates="participations")

    order_items: Mapped[list["OrderItem"]] = relationship(
        back_populates="participation",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        CheckConstraint(
            "participation_role IN ('participant', 'organizer')",
            name="check_participation_role",
        ),
        UniqueConstraint(
            "group_order_id",
            "user_id",
            name="unique_participation",
        ),
        Index(
            "unique_group_order_organizer",
            "group_order_id",
            unique=True,
            postgresql_where=(participation_role == "organizer"),
        ),
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    order_item_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    participation_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("participations.participation_id", ondelete="CASCADE"),
        nullable=False,
    )

    product_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("products.product_id", ondelete="CASCADE"),
        nullable=False,
    )

    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    price_per_unit: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    line_total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

    participation: Mapped["Participation"] = relationship(back_populates="order_items")
    product: Mapped["Product"] = relationship(back_populates="order_items")

    __table_args__ = (
        CheckConstraint("quantity > 0", name="check_order_item_quantity_positive"),
        CheckConstraint("price_per_unit > 0", name="check_order_item_price_positive"),
        CheckConstraint("line_total >= 0", name="check_order_item_line_total"),
    )
