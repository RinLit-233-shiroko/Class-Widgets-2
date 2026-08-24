from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional

import requests
from loguru import logger
from PySide6.QtCore import QObject, Property, QThread, QTimer, Signal, Slot


FORECAST_ENDPOINT = "https://api.open-meteo.com/v1/forecast"
GEOCODING_ENDPOINT = "https://geocoding-api.open-meteo.com/v1/search"


WEATHER_CODES: dict[int, tuple[str, str]] = {
    0: ("Clear", "☀"),
    1: ("Mainly clear", "🌤"),
    2: ("Partly cloudy", "⛅"),
    3: ("Overcast", "☁"),
    45: ("Fog", "🌫"),
    48: ("Rime fog", "🌫"),
    51: ("Light drizzle", "🌦"),
    53: ("Drizzle", "🌦"),
    55: ("Heavy drizzle", "🌧"),
    56: ("Freezing drizzle", "🌧"),
    57: ("Heavy freezing drizzle", "🌧"),
    61: ("Light rain", "🌦"),
    63: ("Rain", "🌧"),
    65: ("Heavy rain", "🌧"),
    66: ("Freezing rain", "🌧"),
    67: ("Heavy freezing rain", "🌧"),
    71: ("Light snow", "🌨"),
    73: ("Snow", "🌨"),
    75: ("Heavy snow", "❄"),
    77: ("Snow grains", "❄"),
    80: ("Light showers", "🌦"),
    81: ("Showers", "🌧"),
    82: ("Heavy showers", "🌧"),
    85: ("Light snow showers", "🌨"),
    86: ("Heavy snow showers", "❄"),
    95: ("Thunderstorm", "⛈"),
    96: ("Thunderstorm with hail", "⛈"),
    99: ("Severe thunderstorm", "⛈"),
}


WEATHER_TEXT_ZH: dict[int, str] = {
    0: "晴朗", 1: "晴间多云", 2: "局部多云", 3: "阴", 45: "雾", 48: "雾凇",
    51: "小毛毛雨", 53: "毛毛雨", 55: "大毛毛雨", 56: "冻毛毛雨", 57: "强冻毛毛雨",
    61: "小雨", 63: "中雨", 65: "大雨", 66: "冻雨", 67: "强冻雨",
    71: "小雪", 73: "中雪", 75: "大雪", 77: "米雪", 80: "小阵雨", 81: "阵雨",
    82: "强阵雨", 85: "小阵雪", 86: "强阵雪", 95: "雷暴", 96: "伴冰雹雷暴",
    99: "强雷暴",
}


@dataclass(frozen=True)
class WeatherSnapshot:
    city: str = ""
    temperature: float = 0.0
    apparent_temperature: float = 0.0
    humidity: int = 0
    wind_speed: float = 0.0
    wind_direction: int = 0
    pressure: float = 0.0
    weather_code: int = -1
    precipitation_probability: int = 0
    high: float = 0.0
    low: float = 0.0
    sunrise: str = ""
    sunset: str = ""
    updated_at: str = ""


class WeatherRequestWorker(QThread):
    """网络请求在工作线程执行，避免刷新天气阻塞桌面 Widget。"""

    succeeded = Signal(object, float, float, str)
    failed = Signal(str)

    def __init__(self, city: str, latitude: Optional[float], longitude: Optional[float], timezone: str) -> None:
        super().__init__()
        self.city = city.strip()
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone or "auto"

    @staticmethod
    def _number(source: dict[str, Any], key: str, default: float = 0.0) -> float:
        try:
            value = source.get(key, default)
            return float(default if value is None else value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _integer(source: dict[str, Any], key: str, default: int = 0) -> int:
        try:
            value = source.get(key, default)
            return int(float(default if value is None else value))
        except (TypeError, ValueError):
            return default

    def run(self) -> None:
        try:
            latitude = self.latitude
            longitude = self.longitude
            city_label = self.city
            if latitude is None or longitude is None:
                if not self.city:
                    raise ValueError("Set a city in Weather settings before refreshing.")
                geo = requests.get(
                    GEOCODING_ENDPOINT,
                    params={"name": self.city, "count": 1, "language": "zh", "format": "json"},
                    timeout=(8, 20),
                )
                geo.raise_for_status()
                results = geo.json().get("results") or []
                if not results:
                    raise ValueError(f"No city was found for '{self.city}'.")
                location = results[0]
                latitude = float(location["latitude"])
                longitude = float(location["longitude"])
                names = [str(location.get("name", "")).strip(), str(location.get("admin1", "")).strip()]
                city_label = " · ".join(name for name in names if name) or self.city

            response = requests.get(
                FORECAST_ENDPOINT,
                params={
                    "latitude": latitude,
                    "longitude": longitude,
                    "timezone": self.timezone,
                    "forecast_days": 1,
                    "current": (
                        "temperature_2m,relative_humidity_2m,apparent_temperature,"
                        "weather_code,surface_pressure,wind_speed_10m,wind_direction_10m"
                    ),
                    "hourly": "precipitation_probability",
                    "daily": "temperature_2m_max,temperature_2m_min,sunrise,sunset",
                },
                timeout=(8, 25),
            )
            response.raise_for_status()
            payload = response.json()
            current = payload.get("current") or {}
            daily = payload.get("daily") or {}
            hourly = payload.get("hourly") or {}
            current_time = str(current.get("time", ""))
            hourly_times = hourly.get("time") or []
            probabilities = hourly.get("precipitation_probability") or []
            probability = 0
            if hourly_times and probabilities:
                try:
                    index = hourly_times.index(current_time)
                except ValueError:
                    index = 0
                if index < len(probabilities):
                    probability = self._integer({"v": probabilities[index]}, "v")

            snapshot = WeatherSnapshot(
                city=city_label,
                temperature=self._number(current, "temperature_2m"),
                apparent_temperature=self._number(current, "apparent_temperature"),
                humidity=self._integer(current, "relative_humidity_2m"),
                wind_speed=self._number(current, "wind_speed_10m"),
                wind_direction=self._integer(current, "wind_direction_10m"),
                pressure=self._number(current, "surface_pressure"),
                weather_code=self._integer(current, "weather_code", -1),
                precipitation_probability=probability,
                high=self._number({"v": (daily.get("temperature_2m_max") or [0])[0]}, "v"),
                low=self._number({"v": (daily.get("temperature_2m_min") or [0])[0]}, "v"),
                sunrise=str((daily.get("sunrise") or [""])[0]),
                sunset=str((daily.get("sunset") or [""])[0]),
                updated_at=datetime.now().strftime("%H:%M"),
            )
            self.succeeded.emit(snapshot, latitude, longitude, city_label)
        except requests.RequestException as error:
            self.failed.emit(f"Weather request failed: {error}")
        except (ValueError, KeyError, IndexError, TypeError) as error:
            self.failed.emit(str(error))
        except Exception as error:
            logger.exception("Unexpected weather refresh error")
            self.failed.emit(f"Unable to refresh weather: {error}")


class WeatherService(QObject):
    """CW2 的共享天气缓存服务。

    基于 Open-Meteo 的公开天气与地理编码接口独立实现，提供与 ClassIsland
    天气组件相似的当前天气、温湿风、体感温度、降水概率及当日高低温信息。
    """

    weatherChanged = Signal()
    loadingChanged = Signal()
    errorChanged = Signal()

    def __init__(self, app, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self.app = app
        self._snapshot = WeatherSnapshot()
        self._worker: Optional[WeatherRequestWorker] = None
        self._loading = False
        self._error = ""
        self._timer = QTimer(self)
        self._timer.timeout.connect(self.refresh)

    @Property(bool, notify=weatherChanged)
    def available(self) -> bool:
        return bool(self._snapshot.city and self._snapshot.weather_code >= 0)

    @Property(bool, notify=loadingChanged)
    def loading(self) -> bool:
        return self._loading

    @Property(str, notify=errorChanged)
    def error(self) -> str:
        return self._error

    @Property(str, notify=weatherChanged)
    def city(self) -> str:
        return self._snapshot.city

    @Property(str, notify=weatherChanged)
    def weatherText(self) -> str:
        code = self._snapshot.weather_code
        if self.app.configs.locale.language.lower().startswith("zh"):
            return WEATHER_TEXT_ZH.get(code, "未知")
        return WEATHER_CODES.get(code, ("Unknown", "?"))[0]

    @Property(str, notify=weatherChanged)
    def weatherIcon(self) -> str:
        return WEATHER_CODES.get(self._snapshot.weather_code, ("Unknown", "?"))[1]

    @Property(float, notify=weatherChanged)
    def temperature(self) -> float:
        return self._snapshot.temperature

    @Property(float, notify=weatherChanged)
    def apparentTemperature(self) -> float:
        return self._snapshot.apparent_temperature

    @Property(int, notify=weatherChanged)
    def humidity(self) -> int:
        return self._snapshot.humidity

    @Property(float, notify=weatherChanged)
    def windSpeed(self) -> float:
        return self._snapshot.wind_speed

    @Property(int, notify=weatherChanged)
    def windDirection(self) -> int:
        return self._snapshot.wind_direction

    @Property(float, notify=weatherChanged)
    def pressure(self) -> float:
        return self._snapshot.pressure

    @Property(int, notify=weatherChanged)
    def precipitationProbability(self) -> int:
        return self._snapshot.precipitation_probability

    @Property(float, notify=weatherChanged)
    def high(self) -> float:
        return self._snapshot.high

    @Property(float, notify=weatherChanged)
    def low(self) -> float:
        return self._snapshot.low

    @Property(str, notify=weatherChanged)
    def sunrise(self) -> str:
        return self._snapshot.sunrise

    @Property(str, notify=weatherChanged)
    def sunset(self) -> str:
        return self._snapshot.sunset

    @Property(str, notify=weatherChanged)
    def updatedAt(self) -> str:
        return self._snapshot.updated_at

    @Slot()
    def initialize(self) -> None:
        self._restart_timer()
        if self.app.configs.weather.enabled and self.app.configs.weather.city.strip():
            self.refresh()

    @Slot()
    def refresh(self) -> None:
        if self._worker is not None or not self.app.configs.weather.enabled:
            return
        config = self.app.configs.weather
        worker = WeatherRequestWorker(config.city, config.latitude, config.longitude, config.timezone)
        self._worker = worker
        self._loading = True
        self._error = ""
        self.loadingChanged.emit()
        self.errorChanged.emit()
        worker.succeeded.connect(self._on_refresh_succeeded)
        worker.failed.connect(self._on_refresh_failed)
        worker.finished.connect(self._on_worker_finished)
        worker.finished.connect(worker.deleteLater)
        worker.start()

    @Slot()
    def refreshFromSettings(self) -> None:
        """城市配置变动后刷新并重新安排周期任务。"""
        self._restart_timer()
        self.refresh()

    @Slot(str)
    def setCity(self, city: str) -> None:
        normalized = (city or "").strip()
        self.app.configs.set("weather.city", normalized)
        # 让城市修改重新进行地理编码，避免沿用旧城市的经纬度。
        self.app.configs.set("weather.latitude", None)
        self.app.configs.set("weather.longitude", None)
        self.app.configs.set("weather.last_city_label", "")
        self.app.configs.save(silent=True)
        self.refreshFromSettings()

    @Slot()
    def release(self) -> None:
        self._timer.stop()
        if self._worker is not None and self._worker.isRunning():
            self._worker.wait(5_000)
        self._worker = None

    def _restart_timer(self) -> None:
        minutes = max(5, min(int(self.app.configs.weather.refresh_interval_minutes), 180))
        self._timer.setInterval(minutes * 60 * 1000)
        self._timer.start()

    @Slot(object, float, float, str)
    def _on_refresh_succeeded(self, snapshot: WeatherSnapshot, latitude: float, longitude: float, city_label: str) -> None:
        self._snapshot = snapshot
        self.app.configs.set("weather.latitude", latitude)
        self.app.configs.set("weather.longitude", longitude)
        self.app.configs.set("weather.last_city_label", city_label)
        self.app.configs.save(silent=True)
        self.weatherChanged.emit()

    @Slot(str)
    def _on_refresh_failed(self, message: str) -> None:
        self._error = message
        self.errorChanged.emit()
        logger.warning("Weather refresh failed: {}", message)

    @Slot()
    def _on_worker_finished(self) -> None:
        if self.sender() is self._worker:
            self._worker = None
            self._loading = False
            self.loadingChanged.emit()
