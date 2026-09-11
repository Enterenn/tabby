"""Background job : génère les dépenses récurrentes dues."""

import asyncio
import calendar
import logging
from datetime import date

from sqlalchemy import extract, select
from sqlalchemy.orm import selectinload

from app.core.database import async_session_factory
from app.models.models import Expense, ExpenseSplit, GroupMember, RecurringExpense

logger = logging.getLogger(__name__)


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
        result = await db.execute(
            select(RecurringExpense)
            .where(RecurringExpense.active.is_(True))
            .options(
                selectinload(RecurringExpense.group),
                selectinload(RecurringExpense.generated_expenses),
            )
        )
        recurrings = result.scalars().all()

        for rec in recurrings:
            # Pas encore le jour du mois
            if today.day < rec.day_of_period:
                continue

            # Vérifier qu'aucune dépense n'a été générée ce mois-ci
            already = await db.execute(
                select(Expense).where(
                    Expense.recurring_source_id == rec.id,
                    extract("year", Expense.expense_date) == today.year,
                    extract("month", Expense.expense_date) == today.month,
                )
            )
            if already.scalar_one_or_none() is not None:
                continue  # déjà générée

            # Calculer la date réelle (protège les mois courts : fév n'a pas le 30)
            last_day = calendar.monthrange(today.year, today.month)[1]
            expense_day = min(rec.day_of_period, last_day)
            expense_date = date(today.year, today.month, expense_day)

            # Récupérer les membres du groupe
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

            expense = Expense(
                id=_uuid.uuid4(),
                group_id=rec.group_id,
                category_id=rec.category_id,
                paid_by=rec.paid_by,
                name=rec.name,
                amount=total,
                expense_date=expense_date,
                recurring_source_id=rec.id,
            )
            db.add(expense)
            await db.flush()

            for m in members:
                split_amt = per_person + (remainder if m.user_id == rec.paid_by else Decimal("0"))
                db.add(ExpenseSplit(
                    id=_uuid.uuid4(),
                    expense_id=expense.id,
                    user_id=m.user_id,
                    amount=split_amt,
                ))

            generated += 1
            logger.info(
                "Generated recurring expense '%s' for %s/%s (group %s)",
                rec.name, today.year, today.month, rec.group_id,
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
