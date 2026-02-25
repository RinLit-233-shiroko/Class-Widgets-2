from datetime import datetime


def get_week_number(start_date: str, current_date: datetime) -> int:
    """
    获取当前日期在开学后的第几周
    :param start_date: 开始计算日期
    :param current_date: datetime.now()
    :return:
    """
    start = datetime.strptime(start_date, "%Y-%m-%d")
    delta_days = (current_date.date() - start.date()).days
    return delta_days // 7 + 1


def get_cycle_week(week_number: int, cycle: int) -> int:
    """
    获取当前周在当前周期的第几周
    :param week_number: 当前周
    :param cycle: 周期
    :return:
    """
    return ((week_number - 1) % cycle) + 1
