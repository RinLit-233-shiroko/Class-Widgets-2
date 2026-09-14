from pathlib import Path

from .cses import CSESConverter
from .cw1 import CW1Converter
from .cw2 import CW2Converter


class ScheduleConverter:
    """
    Universal timetable converter (facade).

    Delegates to per-format converter modules.
    Maintains backward compatibility with the original unified API:

        ScheduleConverter.from_cses(path).to_cw2(output)
        ScheduleConverter.from_cw1(path).to_cw2(output)
        ScheduleConverter.from_cw2(path).to_cses(output)
    """

    @staticmethod
    def from_cses(path: str | Path) -> CSESConverter:
        """Load a CSES YAML file and return a converter ready for to_cw2()."""
        return CSESConverter.from_cses(path)

    @staticmethod
    def from_cw1(path: str | Path) -> CW1Converter:
        """Load a Class Widgets 1 JSON file and return a converter ready for to_cw2()."""
        return CW1Converter.from_cw1(path)

    @staticmethod
    def from_cw2(path: str | Path) -> CW2Converter:
        """Load a Class Widgets 2 JSON file and return a converter ready for to_cses()."""
        return CW2Converter.from_cw2(path)


if __name__ == "__main__":
    from src.core.directories import SCHEDULES_PATH

    ScheduleConverter.from_cw2(Path(SCHEDULES_PATH / "default.json")).to_cses(Path(SCHEDULES_PATH / "New Schedule 1.yaml"))
    # ScheduleConverter.from_cses(Path(SCHEDULES_PATH / "New Schedule 1.yaml")).to_cw2(Path(SCHEDULES_PATH / "New Schedule 1w.json"))
