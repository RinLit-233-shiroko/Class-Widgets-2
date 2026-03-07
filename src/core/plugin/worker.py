import shutil
import zipfile
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot



class PluginImportWorker(QObject):
    finished = Signal(list)
    error = Signal(str)

    def __init__(self, zip_path, external_path, scan_func, metas_ref):
        super().__init__()
        self.zip_path = zip_path
        self.external_path = external_path
        self.scan_func = scan_func
        self.metas_ref = metas_ref  # 引用 self.metas

    @Slot()
    def run(self):
        try:
            old_ids = {m["id"] for m in self.metas_ref}
            old_meta_by_id = {m["id"]: m for m in self.metas_ref}

            with zipfile.ZipFile(self.zip_path, 'r') as zip_ref:
                members = zip_ref.namelist()
                top_dirs = {Path(m).parts[0] for m in members if not m.endswith('/')}

                # 如果有冲突，先删除现有插件
                for plugin_id in old_ids:
                    if plugin_id in [m for m in members if m.endswith('cwplugin.json')]:
                        # 删除已存在的插件
                        plugin_path = self.external_path / plugin_id
                        if plugin_path.exists():
                            shutil.rmtree(plugin_path)

                if len(top_dirs) == 1:
                    # 单一插件ZIP，直接解压到外部路径
                    zip_ref.extractall(self.external_path)
                else:
                    # 多插件ZIP或复杂结构
                    target_dir = self.external_path / Path(self.zip_path).stem
                    if target_dir.exists():
                        shutil.rmtree(target_dir)
                    zip_ref.extractall(target_dir)

            self.scan_func()
            new_ids = {m["id"] for m in self.metas_ref}
            new_meta_by_id = {m["id"]: m for m in self.metas_ref}

            # 计算新增和更新的插件
            new_plugins = list(new_ids - old_ids)
            updated_plugins = list(new_ids & old_ids)  # 简单处理：所有冲突插件都算更新

            result = {
                "new_plugins": new_plugins,
                "updated_plugins": updated_plugins,
                "all_imported": new_plugins + updated_plugins
            }
            
            self.finished.emit([result])

        except Exception as e:
            self.error.emit(str(e))