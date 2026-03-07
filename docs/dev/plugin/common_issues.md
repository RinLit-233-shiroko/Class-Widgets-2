# 常见问题和注意事项

## 重要注意事项

### 1. 类名规范
```python
# 主类必须命名为 Plugin
class Plugin(CW2Plugin):
    pass
```

### 2. 信号槽方法
```python
# 使用 @Slot 装饰器，否则无法在QML前端调用
from PySide6.QtCore import Slot

class Plugin(CW2Plugin):
    @Slot(str)
    def my_method(self, param: str):
        pass

    @Slot(result=str)
    def get_value(self) -> str:
        return "value"
```

### 3. 资源文件路径
```python
# 1st: 使用相对路径
from pathlib import Path

def _register_settings_page(self):
    plugin_dir = Path(__file__).parent
    settings_qml = plugin_dir / "assets" / "settings.qml"
    
    self.api.ui.register_settings_page(
        qml_path=str(settings_qml.relative_to(plugin_dir)),
        title="设置"
    )

# 2nd: 使用 Plugin 类的 `self.PATH` 拼接
```

## 常见问题

### 插件加载失败
**错误**: "Plugin entry file does not define a 'Plugin' class"
**解决**: 确保主类命名为 `Plugin`

### QML 访问 Python 失败
**错误**: "Cannot read property 'data' of null"
**解决**: 
1. 确保在 Widget 注册时设置 `backend_obj=self`
2. 确保方法使用 `@Slot` 装饰器

### 配置不保存
**问题**: 配置修改后重启失效
**解决**: 在 `on_load()` 中正确注册配置模型