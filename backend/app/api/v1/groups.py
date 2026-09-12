import secrets
import string
import uuid
from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.balance import ExpenseRecord, compute_balances, user_balance
from app.core.database import get_db
from app.core.deps import get_current_user, require_group_member, require_group_owner
from app.core.rate_limit import limiter
from app.core.uploads import avatar_public_url
from app.models.models import Expense, ExpenseSplit, Group, GroupInvite, GroupMember, User
from app.schemas.group import (
    BalanceEntry,
    GroupCreate,
    GroupPinUpdate,
    GroupResponse,
    GroupUpdate,
    InviteResponse,
    JoinRequest,
    MemberResponse,
    SettleRequest,
)
from app.schemas.auth import UserResponse
from decimal import Decimal

router = APIRouter(prefix="/groups", tags=["groups"])


_INVITE_ALPHABET = string.ascii_uppercase + string.digits


def _invite_code() -> str:
    return "".join(secrets.choice(_INVITE_ALPHABET) for _ in range(8))


def _group_response(
    group: Group,
    members: list[GroupMember],
    expenses: list[Expense],
    current_user_id: uuid.UUID,
) -> GroupResponse:
    records = [
        ExpenseRecord(
            paid_by=str(e.paid_by),
            splits=[(str(s.user_id), Decimal(str(s.amount))) for s in e.splits],
        )
        for e in expenses
    ]
    debts = compute_balances(records)
    balance = user_balance(str(current_user_id), debts)
    membership = next((m for m in members if m.user_id == current_user_id), None)

    return GroupResponse(
        id=str(group.id),
        name=group.name,
        owner_id=str(group.owner_id),
        created_at=group.created_at,
        members=[
            MemberResponse(
                user=UserResponse(
                    id=str(m.user.id),
                    name=m.user.name,
                    email=m.user.email,
                    avatar_url=avatar_public_url(str(m.user.id)) if m.user.avatar_url else None,
                ),
                joined_at=m.joined_at,
            )
            for m in members
        ],
        balance=balance,
        is_pinned=membership.is_pinned if membership else False,
    )


async def _load_group_with_balance(
    group: Group, current_user_id: uuid.UUID, db: AsyncSession
) -> GroupResponse:
    """Charge les membres et calcule le solde de l'utilisateur courant."""
    result = await db.execute(
        select(GroupMember)
        .where(GroupMember.group_id == group.id)
        .options(selectinload(GroupMember.user))
    )
    members = list(result.scalars().all())

    exp_result = await db.execute(
        select(Expense)
        .where(Expense.group_id == group.id)
        .options(selectinload(Expense.splits))
    )
    expenses = list(exp_result.scalars().all())
    return _group_response(group, members, expenses, current_user_id)


@router.get("", response_model=list[GroupResponse])
async def list_groups(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Group)
        .join(GroupMember, GroupMember.group_id == Group.id)
        .where(GroupMember.user_id == current_user.id)
        .order_by(GroupMember.is_pinned.desc(), Group.created_at.desc())
    )
    groups = result.scalars().all()
    if not groups:
        return []

    ids = [g.id for g in groups]
    members_result = await db.execute(
        select(GroupMember)
        .where(GroupMember.group_id.in_(ids))
        .options(selectinload(GroupMember.user))
    )
    members_by: dict[uuid.UUID, list[GroupMember]] = defaultdict(list)
    for member in members_result.scalars().all():
        members_by[member.group_id].append(member)

    expenses_result = await db.execute(
        select(Expense)
        .where(Expense.group_id.in_(ids))
        .options(selectinload(Expense.splits))
    )
    expenses_by: dict[uuid.UUID, list[Expense]] = defaultdict(list)
    for expense in expenses_result.scalars().all():
        expenses_by[expense.group_id].append(expense)

    return [
        _group_response(group, members_by[group.id], expenses_by[group.id], current_user.id)
        for group in groups
    ]


@router.post("", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
async def create_group(
    body: GroupCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    group = Group(id=uuid.uuid4(), name=body.name, owner_id=current_user.id)
    db.add(group)
    await db.flush()

    membership = GroupMember(group_id=group.id, user_id=current_user.id)
    db.add(membership)
    await db.flush()

    return await _load_group_with_balance(group, current_user.id, db)


@router.get("/{group_id}", response_model=GroupResponse)
async def get_group(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    group = await db.get(Group, group_id)
    if group is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    return await _load_group_with_balance(group, current_user.id, db)


@router.patch("/{group_id}/pin", response_model=GroupResponse)
async def set_group_pin(
    group_id: uuid.UUID,
    body: GroupPinUpdate,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    membership = await db.get(GroupMember, (group_id, current_user.id))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")
    membership.is_pinned = body.is_pinned
    await db.flush()
    group = await db.get(Group, group_id)
    if group is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    return await _load_group_with_balance(group, current_user.id, db)


@router.patch("/{group_id}", response_model=GroupResponse)
async def update_group(
    group_id: uuid.UUID,
    body: GroupUpdate,
    current_user: User = Depends(require_group_owner),
    db: AsyncSession = Depends(get_db),
):
    group = await db.get(Group, group_id)
    if group is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    group.name = body.name
    return await _load_group_with_balance(group, current_user.id, db)


@router.delete("/{group_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_owner),
    db: AsyncSession = Depends(get_db),
):
    group = await db.get(Group, group_id)
    if group is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    await db.delete(group)
    await db.flush()  # Remonte les erreurs FK avant l'envoi du 204


@router.post("/{group_id}/invite", response_model=InviteResponse)
async def create_invite(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    # Générer un code unique à 6 chiffres
    for _ in range(10):
        code = _invite_code()
        existing = await db.execute(select(GroupInvite).where(GroupInvite.code == code))
        if existing.scalar_one_or_none() is None:
            break
    else:
        raise HTTPException(status_code=500, detail="Could not generate unique invite code")

    invite = GroupInvite(
        id=uuid.uuid4(),
        group_id=group_id,
        code=code,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=24),
    )
    db.add(invite)
    await db.flush()
    return InviteResponse(code=invite.code, expires_at=invite.expires_at)


@router.post("/join", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/minute")
async def join_group(
    request: Request,
    body: JoinRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(GroupInvite).where(GroupInvite.code == body.code))
    invite = result.scalar_one_or_none()

    if invite is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid invite code")
    if invite.used_at is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Invite already used")
    if invite.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Invite expired")

    # Vérifier si déjà membre
    existing = await db.get(GroupMember, (invite.group_id, current_user.id))
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already a member")

    invite.used_at = datetime.now(timezone.utc)
    membership = GroupMember(group_id=invite.group_id, user_id=current_user.id)
    db.add(membership)
    await db.flush()

    group = await db.get(Group, invite.group_id)
    return await _load_group_with_balance(group, current_user.id, db)


@router.get("/{group_id}/balances", response_model=list[BalanceEntry])
async def get_group_balances(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    """Retourne la liste minimale de transferts pour solder le groupe, avec les noms."""
    exp_result = await db.execute(
        select(Expense)
        .where(Expense.group_id == group_id)
        .options(selectinload(Expense.splits))
    )
    expenses = exp_result.scalars().all()

    members_result = await db.execute(
        select(GroupMember)
        .where(GroupMember.group_id == group_id)
        .options(selectinload(GroupMember.user))
    )
    members = members_result.scalars().all()
    name_map = {str(m.user.id): m.user.name for m in members}

    records = [
        ExpenseRecord(
            paid_by=str(e.paid_by),
            splits=[(str(s.user_id), Decimal(str(s.amount))) for s in e.splits],
        )
        for e in expenses
    ]
    debts = compute_balances(records)

    return [
        BalanceEntry(
            from_user_id=d.debtor,
            from_user_name=name_map.get(d.debtor, "?"),
            to_user_id=d.creditor,
            to_user_name=name_map.get(d.creditor, "?"),
            amount=d.amount,
        )
        for d in debts
    ]


@router.post("/{group_id}/settle", status_code=status.HTTP_201_CREATED)
async def settle_debt(
    group_id: uuid.UUID,
    body: SettleRequest,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    """Enregistre un remboursement entre deux membres en créant une dépense spéciale."""
    from app.models.models import Category

    # Chercher/créer la catégorie "Remboursement"
    cat_result = await db.execute(
        select(Category).where(Category.name == "Remboursement")
    )
    category = cat_result.scalar_one_or_none()
    if category is None:
        category = Category(
            id=uuid.uuid4(),
            name="Remboursement",
            icon="payments",
            color="#7F8C8D",
            is_default=True,
            sort_order=99,
        )
        db.add(category)
        await db.flush()

    try:
        from_user_id = uuid.UUID(str(body.from_user_id))
        to_user_id = uuid.UUID(str(body.to_user_id))
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user id",
        )
    from_member = await db.get(GroupMember, (group_id, from_user_id))
    to_member = await db.get(GroupMember, (group_id, to_user_id))
    if from_member is None or to_member is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Both users must be members of this group",
        )
    if from_user_id == to_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot settle with the same user",
        )

    amount = Decimal(str(body.amount)).quantize(Decimal("0.01"))
    if amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Amount must be greater than zero",
        )
    expense = Expense(
        id=uuid.uuid4(),
        group_id=group_id,
        category_id=category.id,
        paid_by=from_user_id,
        name="Remboursement",
        amount=amount,
        expense_date=datetime.now(timezone.utc).date(),
    )
    db.add(expense)
    await db.flush()

    # Split : 100% à to_user (celui qui est remboursé)
    db.add(ExpenseSplit(
        id=uuid.uuid4(),
        expense_id=expense.id,
        user_id=to_user_id,
        amount=amount,
    ))
    await db.flush()
    return {"ok": True}


@router.post("/{group_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
async def leave_group(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    """Quitte le groupe. Refusé si le solde n'est pas nul."""
    exp_result = await db.execute(
        select(Expense)
        .where(Expense.group_id == group_id)
        .options(selectinload(Expense.splits))
    )
    expenses = exp_result.scalars().all()
    records = [
        ExpenseRecord(
            paid_by=str(e.paid_by),
            splits=[(str(s.user_id), Decimal(str(s.amount))) for s in e.splits],
        )
        for e in expenses
    ]
    debts = compute_balances(records)
    balance = user_balance(str(current_user.id), debts)
    if abs(balance) > 0.01:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Solde non nul ({balance:+.2f}€). Réglez vos dettes avant de quitter.",
        )

    group = await db.get(Group, group_id)
    if group is not None and group.owner_id == current_user.id:
        others_result = await db.execute(
            select(GroupMember)
            .where(GroupMember.group_id == group_id, GroupMember.user_id != current_user.id)
            .order_by(GroupMember.joined_at.asc())
        )
        successor = others_result.scalars().first()
        if successor is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Delete the group instead of leaving as the last owner",
            )
        group.owner_id = successor.user_id

    membership = await db.get(GroupMember, (group_id, current_user.id))
    if membership:
        await db.delete(membership)
        await db.flush()


@router.delete("/{group_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(
    group_id: uuid.UUID,
    user_id: uuid.UUID,
    current_user: User = Depends(require_group_owner),
    db: AsyncSession = Depends(get_db),
):
    group = await db.get(Group, group_id)
    if group is not None and group.owner_id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot remove the group owner",
        )
    membership = await db.get(GroupMember, (group_id, user_id))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")
    await db.delete(membership)
