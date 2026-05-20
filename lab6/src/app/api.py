from typing import Literal
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, text, or_, asc, desc
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import (
    get_db,
    User,
    Supplier,
    Product,
    GroupOrder,

)

from app.models import (
    UserBase,
    UserCreate,
    UserUpdate,
    UserRead,
    SupplierBase,
    SupplierCreate,
    SupplierUpdate,
    SupplierRead,
    ProductBase,
    ProductCreate,
    ProductUpdate,
    ProductRead,
    GroupOrderBase,
    GroupOrderCreate,
    GroupOrderUpdate,
    GroupOrderRead,
    JoinGroupOrderRequest,
    AddOrderItemRequest
)

router = APIRouter()


def apply_list_params(
        stmt,
        model,
        allowed_sort_fields: set[str],
        filter_value: str | None,
        filter_fields: list,
        sort: str,
        order: str,
        page: int,
        limit: int,
):
    if filter_value:
        stmt = stmt.where(
            or_(*[field.ilike(f"%{filter_value}%") for field in filter_fields])
        )

    if sort not in allowed_sort_fields:
        raise HTTPException(
            status_code=400,
            detail=f"Сортировка по полю '{sort}' не разрешена",
        )

    sort_column = getattr(model, sort)

    if order == "desc":
        stmt = stmt.order_by(desc(sort_column))
    else:
        stmt = stmt.order_by(asc(sort_column))

    offset = (page - 1) * limit
    return stmt.offset(offset).limit(limit)


async def commit_or_rollback(db: AsyncSession):
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка ограничения БД: {str(e.orig)}",
        )
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка базы данных: {str(e)}",
        )


async def get_object_or_404(db: AsyncSession, model, pk_field, pk_value):
    result = await db.execute(select(model).where(pk_field == pk_value))
    obj = result.scalar_one_or_none()

    if obj is None:
        raise HTTPException(status_code=404, detail="Запись не найдена")

    return obj


@router.get("/ping")
async def ping():
    return {"ping": "pong"}



# CRUD: Users
@router.get("/users", response_model=list[UserRead])
async def get_users(
        page: int = Query(1, ge=1),
        limit: int = Query(10, ge=1, le=100),
        sort: str = "user_id",
        order: Literal["asc", "desc"] = "asc",
        filter: str | None = None,
        db: AsyncSession = Depends(get_db),
):
    stmt = select(User)

    stmt = apply_list_params(
        stmt=stmt,
        model=User,
        allowed_sort_fields={"user_id", "full_name", "email", "phone"},
        filter_value=filter,
        filter_fields=[User.full_name, User.email, User.phone],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )

    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/users/{user_id}", response_model=UserRead)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, User, User.user_id, user_id)


@router.post("/users", response_model=UserRead, status_code=201)
async def create_user(data: UserCreate, db: AsyncSession = Depends(get_db)):
    user = User(**data.model_dump())
    db.add(user)
    await commit_or_rollback(db)
    await db.refresh(user)
    return user


@router.put("/users/{user_id}", response_model=UserRead)
async def update_user(user_id: int, data: UserUpdate, db: AsyncSession = Depends(get_db)):
    user = await get_object_or_404(db, User, User.user_id, user_id)

    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(user, key, value)

    await commit_or_rollback(db)
    await db.refresh(user)
    return user


@router.delete("/users/{user_id}")
async def delete_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await get_object_or_404(db, User, User.user_id, user_id)
    await db.delete(user)
    await commit_or_rollback(db)
    return {"message": "Пользователь удален"}



# CRUD: Suppliers
@router.get("/suppliers", response_model=list[SupplierRead])
async def get_suppliers(
        page: int = Query(1, ge=1),
        limit: int = Query(10, ge=1, le=100),
        sort: str = "supplier_id",
        order: Literal["asc", "desc"] = "asc",
        filter: str | None = None,
        db: AsyncSession = Depends(get_db),
):
    stmt = select(Supplier)

    stmt = apply_list_params(
        stmt=stmt,
        model=Supplier,
        allowed_sort_fields={"supplier_id", "name", "supplier_type"},
        filter_value=filter,
        filter_fields=[Supplier.name, Supplier.supplier_type],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )

    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/suppliers/{supplier_id}", response_model=SupplierRead)
async def get_supplier(supplier_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, Supplier, Supplier.supplier_id, supplier_id)


@router.post("/suppliers", response_model=SupplierRead, status_code=201)
async def create_supplier(data: SupplierCreate, db: AsyncSession = Depends(get_db)):
    supplier = Supplier(**data.model_dump())
    db.add(supplier)
    await commit_or_rollback(db)
    await db.refresh(supplier)
    return supplier


@router.put("/suppliers/{supplier_id}", response_model=SupplierRead)
async def update_supplier(supplier_id: int, data: SupplierUpdate, db: AsyncSession = Depends(get_db)):
    supplier = await get_object_or_404(db, Supplier, Supplier.supplier_id, supplier_id)

    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(supplier, key, value)

    await commit_or_rollback(db)
    await db.refresh(supplier)
    return supplier


@router.delete("/suppliers/{supplier_id}")
async def delete_supplier(supplier_id: int, db: AsyncSession = Depends(get_db)):
    supplier = await get_object_or_404(db, Supplier, Supplier.supplier_id, supplier_id)
    await db.delete(supplier)
    await commit_or_rollback(db)
    return {"message": "Поставщик удален"}



# CRUD: Products
@router.get("/products", response_model=list[ProductRead])
async def get_products(
        page: int = Query(1, ge=1),
        limit: int = Query(10, ge=1, le=100),
        sort: str = "product_id",
        order: Literal["asc", "desc"] = "asc",
        filter: str | None = None,
        db: AsyncSession = Depends(get_db),
):
    stmt = select(Product)

    stmt = apply_list_params(
        stmt=stmt,
        model=Product,
        allowed_sort_fields={"product_id", "supplier_id", "name", "price", "is_active"},
        filter_value=filter,
        filter_fields=[Product.name, Product.description],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )

    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/products/{product_id}", response_model=ProductRead)
async def get_product(product_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, Product, Product.product_id, product_id)


@router.post("/products", response_model=ProductRead, status_code=201)
async def create_product(data: ProductCreate, db: AsyncSession = Depends(get_db)):
    product = Product(**data.model_dump())
    db.add(product)
    await commit_or_rollback(db)
    await db.refresh(product)
    return product


@router.put("/products/{product_id}", response_model=ProductRead)
async def update_product(product_id: int, data: ProductUpdate, db: AsyncSession = Depends(get_db)):
    product = await get_object_or_404(db, Product, Product.product_id, product_id)

    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(product, key, value)

    await commit_or_rollback(db)
    await db.refresh(product)
    return product


@router.delete("/products/{product_id}")
async def delete_product(product_id: int, db: AsyncSession = Depends(get_db)):
    product = await get_object_or_404(db, Product, Product.product_id, product_id)
    await db.delete(product)
    await commit_or_rollback(db)
    return {"message": "Товар удален"}



# CRUD: GroupOrders
@router.get("/group-orders", response_model=list[GroupOrderRead])
async def get_group_orders(
        page: int = Query(1, ge=1),
        limit: int = Query(10, ge=1, le=100),
        sort: str = "group_order_id",
        order: Literal["asc", "desc"] = "asc",
        filter: str | None = None,
        db: AsyncSession = Depends(get_db),
):
    stmt = select(GroupOrder)

    stmt = apply_list_params(
        stmt=stmt,
        model=GroupOrder,
        allowed_sort_fields={
            "group_order_id",
            "supplier_id",
            "title",
            "status",
            "min_participants",
            "min_total_amount",
        },
        filter_value=filter,
        filter_fields=[GroupOrder.title, GroupOrder.description, GroupOrder.status],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )

    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/group-orders/{group_order_id}", response_model=GroupOrderRead)
async def get_group_order(group_order_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, GroupOrder, GroupOrder.group_order_id, group_order_id)


@router.post("/group-orders", response_model=GroupOrderRead, status_code=201)
async def create_group_order(data: GroupOrderCreate, db: AsyncSession = Depends(get_db)):
    group_order = GroupOrder(**data.model_dump())
    db.add(group_order)
    await commit_or_rollback(db)
    await db.refresh(group_order)
    return group_order


@router.put("/group-orders/{group_order_id}", response_model=GroupOrderRead)
async def update_group_order(group_order_id: int, data: GroupOrderUpdate, db: AsyncSession = Depends(get_db)):
    group_order = await get_object_or_404(db, GroupOrder, GroupOrder.group_order_id, group_order_id)

    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(group_order, key, value)

    await commit_or_rollback(db)
    await db.refresh(group_order)
    return group_order


@router.delete("/group-orders/{group_order_id}")
async def delete_group_order(group_order_id: int, db: AsyncSession = Depends(get_db)):
    group_order = await get_object_or_404(db, GroupOrder, GroupOrder.group_order_id, group_order_id)

    await db.delete(group_order)
    await commit_or_rollback(db)
    return {"message": "Групповая закупка удалена"}



# Views
@router.get("/views/group-orders-summary")
async def get_group_orders_summary(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT *
            FROM group_orders_summary
            ORDER BY group_order_id
        """)
    )

    return [dict(row._mapping) for row in result.fetchall()]


@router.get("/views/users-activity-summary")
async def get_users_activity_summary(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT *
            FROM users_activity_summary
            ORDER BY user_id
        """)
    )

    return [dict(row._mapping) for row in result.fetchall()]



# Functions
@router.get("/group-orders/{group_order_id}/total")
async def get_group_order_total_endpoint(group_order_id: int, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            text("""
                SELECT get_group_order_total(:group_order_id) AS total_amount
            """),
            {"group_order_id": group_order_id},
        )

        row = result.fetchone()

        return {
            "group_order_id": group_order_id,
            "total_amount": row.total_amount,
        }

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове функции get_group_order_total: {str(e)}",
        )


@router.get("/group-orders/{group_order_id}/ready")
async def is_group_order_ready_endpoint(
        group_order_id: int,
        db: AsyncSession = Depends(get_db),
):
    try:
        result = await db.execute(
            text("""
                SELECT is_group_order_ready(:group_order_id) AS is_ready
            """),
            {"group_order_id": group_order_id},
        )

        row = result.fetchone()

        return {
            "group_order_id": group_order_id,
            "is_ready": row.is_ready,
        }

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове функции is_group_order_ready: {str(e)}",
        )



# Procedures
@router.post("/group-orders/{group_order_id}/join")
async def join_group_order_endpoint(
        group_order_id: int,
        data: JoinGroupOrderRequest,
        db: AsyncSession = Depends(get_db),
):
    try:
        await db.execute(
            text("""
                CALL join_group_order(
                    :group_order_id,
                    :user_id,
                    :participation_role
                )
            """),
            {
                "group_order_id": group_order_id,
                "user_id": data.user_id,
                "participation_role": data.participation_role,
            },
        )

        await db.commit()

        return {
            "message": "Пользователь добавлен в групповую закупку",
            "group_order_id": group_order_id,
            "user_id": data.user_id,
            "participation_role": data.participation_role,
        }

    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове процедуры join_group_order: {str(e)}",
        )


@router.post("/order-items/add")
async def add_order_item_endpoint(data: AddOrderItemRequest, db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(
            text("""
                CALL add_order_item(
                    :participation_id,
                    :product_id,
                    :quantity
                )
            """),
            {
                "participation_id": data.participation_id,
                "product_id": data.product_id,
                "quantity": data.quantity,
            },
        )

        await db.commit()

        return {
            "message": "Товар добавлен в заказ",
            "participation_id": data.participation_id,
            "product_id": data.product_id,
            "quantity": data.quantity,
        }

    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове процедуры add_order_item: {str(e)}",
        )



# Audit
@router.get("/audit/group-order-status")
async def get_group_order_status_audit(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT
                audit_id,
                group_order_id,
                old_status,
                new_status,
                changed_at
            FROM group_order_status_audit
            ORDER BY changed_at DESC
        """)
    )

    return [dict(row._mapping) for row in result.fetchall()]



# Reports
@router.get("/reports/users-activity")
async def report_users_activity(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT
                user_id,
                full_name,
                email,
                created_orders_count,
                participations_count,
                total_ordered_amount
            FROM users_activity_summary
            ORDER BY total_ordered_amount DESC
        """)
    )

    return [dict(row._mapping) for row in result.fetchall()]


@router.get("/reports/top-users")
async def report_top_users(limit: int = Query(10, ge=1, le=100), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT
                user_id,
                full_name,
                email,
                created_orders_count,
                participations_count,
                total_ordered_amount
            FROM users_activity_summary
            ORDER BY total_ordered_amount DESC
            LIMIT :limit
        """),
        {"limit": limit},
    )

    return [dict(row._mapping) for row in result.fetchall()]


@router.get("/reports/ready-group-orders")
async def report_ready_group_orders(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT
                go.group_order_id,
                go.title,
                go.status,
                get_group_order_total(go.group_order_id) AS total_amount,
                is_group_order_ready(go.group_order_id) AS is_ready
            FROM group_orders go
            ORDER BY go.group_order_id
        """)
    )

    return [dict(row._mapping) for row in result.fetchall()]
