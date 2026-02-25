import json
from pathlib import Path
from typing import Any, Optional, Union


class JsonLoader:
    def __init__(self, path: Union[str, Path], default: Optional[Any] = None):
        self.default = default
        self.path = Path(path)
        self.data = default

    def load(self) -> Any:
        if not self.path.exists():
            raise FileNotFoundError(f"Config file not exists: {self.path}")

        try:
            with open(self.path, "r", encoding="utf-8") as f:
                content = f.read().strip()
                if not content:  # 文件是空的
                    self.data = {}
                    return self.data
                self.data = json.loads(content)
        except json.JSONDecodeError as e:
            raise ValueError(
                f"Config file is not a valid JSON format: {self.path}\n详情: {e}"
            )
        except Exception as e:
            raise RuntimeError(f"Load config file failed: {e}")

        return self.data

    def get(self) -> Any:
        return self.data

    def save(self, data: Any) -> None:
        try:
            with open(self.path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4, ensure_ascii=False)
        except Exception as e:
            raise RuntimeError(f"Save config file failed: {e}")


# 用法示例
if __name__ == "__main__":
    loader = JsonLoader(Path("../data/schedule.json"))
    loader.load()
    print(loader.get())
