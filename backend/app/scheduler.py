"""Background job : génère les dépenses récurrentes dues."""

import asyncio
import calendar
import logging
from datetime import date

from sqlalchemy import select, text
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import selectinload

from app.core.database import async_session_factory
from app.models.models import (
    Expense,
    ExpenseSplit,
    GroupMember,
    PersonalExpense,
    PersonalRecurring,
    RecurringExpense,
)

logger = logging.getLogger(__name__)


def period_expense_date(today: date, day_of_period: int) -> date | None:
    """Date du mois courant, ou None si le jour n'est pas encore passé."""
    if today.day < day_of_period:
        return None
    last_day = calendar.monthrange(today.year, today.month)[1]
    return date(today.year, today.month, min(day_of_period, last_day))


SCHEDULER_LOCK_KEY = 7_314_159


async def generate_recurring_expenses() -> int:
    """
    Pour chaque récurrence active dont day_of_period <= aujourd'hui,
    crée l'expense du mois courant si elle n'existe pas encore.
    Retourne le nombre de dépenses générées.
    """
    from decimal import Decimal, ROUND_HALF_UP
    import uuid as _uuid

    today = date.today()
    generated = 0

    async with async_session_factory() as db:
        lock_result = await db.execute(
            text("SELECT pg_try_advisory_xact_lock(:lock_key)"),
            {"lock_key": SCHEDULER_LOCK_KEY},
        )
        if not lock_result.scalar():
            logger.info("Recurring job skipped: another instance owns the lock")
            return 0

        result = await db.execute(
            select(RecurringExpense)
            .where(RecurringExpense.active.is_(True))
            .options(selectinload(RecurringExpense.group))
        )
        recurrings = result.scalars().all()

        for rec in recurrings:
            expense_date = period_expense_date(today, rec.day_of_period)
            if expense_date is None:
                continue


            members_result = await db.execute(
                select(GroupMember).where(GroupMember.group_id == rec.group_id)
            )
            members = members_result.scalars().all()
            n = len(members)
            if n == 0:
                continue

            total = Decimal(str(rec.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            per_person = (total / n).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            remainder = total - per_person * n

            expense_id = _uuid.uuid4()
            expense_values = {
                "id": expense_id,
                "group_id": rec.group_id,
                "category_id": rec.category_id,
                "paid_by": rec.paid_by,
                "name": rec.name,
                "amount": total,
                "expense_date": expense_date,
                "recurring_source_id": rec.id,
            }
            inserted = await db.execute(
                pg_insert(Expense)
                .values(**expense_values)
                .on_conflict_do_nothing(
                    index_elements=[Expense.recurring_source_id, Expense.expense_date]
                )
                .returning(Expense.id)
            )
            if inserted.scalar_one_or_none() is None:
                continue

            for m in members:
                split_amt = per_person + (remainder if m.user_id == rec.paid_by else Decimal("0"))
                db.add(ExpenseSplit(
                    id=_uuid.uuid4(),
                    expense_id=expense_id,
                    user_id=m.user_id,
                    amount=split_amt,
                ))

            generated += 1
            logger.info(
                "Generated recurring expense '%s' for %s/%s (group %s)",
                rec.name, today.year, today.month, rec.group_id,
            )

        personal_result = await db.execute(
            select(PersonalRecurring).where(PersonalRecurring.active.is_(True))
        )
        for rec in personal_result.scalars().all():
            expense_date = period_expense_date(today, rec.day_of_period)
            if expense_date is None:
                continue


            personal_expense_id = _uuid.uuid4()
            inserted = await db.execute(
                pg_insert(PersonalExpense)
                .values(
                    id=personal_expense_id,
                    user_id=rec.user_id,
                    category_id=rec.category_id,
                    name=rec.name,
                    amount=Decimal(str(rec.amount)).quantize(
                        Decimal("0.01"), rounding=ROUND_HALF_UP
                    ),
                    expense_date=expense_date,
                    recurring_source_id=rec.id,
                )
                .on_conflict_do_nothing(
                    index_elements=[
                        PersonalExpense.recurring_source_id,
                        PersonalExpense.expense_date,
                    ]
                )
                .returning(PersonalExpense.id)
            )
            if inserted.scalar_one_or_none() is None:
                continue

            generated += 1
            logger.info(
                "Generated personal recurring '%s' for %s/%s (user %s)",
                rec.name, today.year, today.month, rec.user_id,
            )

        await db.commit()

    return generated


async def recurring_job_loop() -> None:
    """Lance la génération au démarrage puis toutes les 6 heures."""
    while True:
        try:
            n = await generate_recurring_expenses()
            if n:
                logger.info("Recurring job: %d expense(s) generated", n)
        except Exception:
            logger.exception("Recurring job failed")
        await asyncio.sleep(6 * 3600)
