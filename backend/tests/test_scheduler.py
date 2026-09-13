from datetime import date

from app.scheduler import period_expense_date


def test_period_date_waits_until_the_day():
    assert period_expense_date(date(2026, 9, 4), 5) is None


def test_period_date_uses_the_requested_day():
    assert period_expense_date(date(2026, 9, 13), 5) == date(2026, 9, 5)


def test_period_date_clamps_short_months():
    assert period_expense_date(date(2026, 2, 28), 28) == date(2026, 2, 28)
