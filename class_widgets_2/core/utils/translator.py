from pathlib import Path

from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QObject, Signal, Slot, QTranslator, QLocale
from loguru import logger
from RinUI import RinUITranslator

from class_widgets_2.core import ASSETS_PATH


class AppTranslator(QObject):
    languageChanged = Signal(str)

    def __init__(self, app):
        super().__init__()
        self.central = app
        self.app = QApplication.instance()
        self.translator = QTranslator()
        self.rinui_translator = None

    @Slot(result=str)
    def getLanguage(self):
        """获取当前语言"""
        return self.central.configs.locale.language

    @Slot(result=str)
    def getSystemLanguage(self):
        return QLocale.system().name()

    @Slot(str)
    def setLanguage(self, locale_name: str):  # sample: zh_CN; en_US
        """切换语言"""
        lang_path = Path(ASSETS_PATH / "locales" / f"{locale_name}.qm")
        if not lang_path.exists():  # fallback
            logger.warning(f"Language file {lang_path} not found. Fallback to default (en_US)")
            # locale_name = "en_US"

        self.rinui_translator = RinUITranslator(QLocale(locale_name))
        self.translator = QTranslator()
        self.translator.load(lang_path.as_posix())
        QLocale.setDefault(QLocale(locale_name))

        self.app.removeTranslator(self.translator)
        self.app.removeTranslator(self.rinui_translator)
        self.app.installTranslator(self.translator)
        self.app.installTranslator(self.rinui_translator)
        self.central.configs.locale.language = locale_name
        self.languageChanged.emit(locale_name)
        logger.info(f"Translator loaded: {locale_name}")


    @Slot(str, str, result=str)
    def tr(self, context: str, source_text: str) -> str:
        """提供 QML 访问翻译的接口"""
        return QApplication.translate(context, source_text)
