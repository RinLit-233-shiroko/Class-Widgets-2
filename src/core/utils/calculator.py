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
    if delta_days >= 0:
        return delta_days // 7 + 1
    # 开学日前：按周继续向前编号，不产生 0 周
    # 例如：开学前 1~7 天 -> -1，前 8~14 天 -> -2
    return -(((-delta_days) + 6) // 7)


def get_cycle_week(week_number: int, cycle: int) -> int:
    """
    获取当前周在当前周期的第几周
    :param week_number: 当前周
    :param cycle: 周期
    :return:
    """
    # 正周次：1,2,3... 正常循环
    if week_number >= 1:
        return ((week_number - 1) % cycle) + 1
    # 负周次：按“向前排”规则循环
    # cycle=2 时：-1 -> 2(双周), -2 -> 1(单周)
    return (week_number % cycle) + 1
