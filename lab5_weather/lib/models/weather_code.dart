import 'package:flutter/material.dart';

// Open-Meteo отдаёт погоду кодом WMO, а не текстом.
// Таблица кодов: https://open-meteo.com/en/docs (раздел WMO Weather interpretation codes)
String weatherDescription(int code) {
  switch (code) {
    case 0:
      return 'Ясно';
    case 1:
      return 'Преимущественно ясно';
    case 2:
      return 'Переменная облачность';
    case 3:
      return 'Пасмурно';
    case 45:
    case 48:
      return 'Туман';
    case 51:
    case 53:
    case 55:
      return 'Морось';
    case 56:
    case 57:
      return 'Ледяная морось';
    case 61:
      return 'Небольшой дождь';
    case 63:
      return 'Дождь';
    case 65:
      return 'Сильный дождь';
    case 66:
    case 67:
      return 'Ледяной дождь';
    case 71:
      return 'Небольшой снег';
    case 73:
      return 'Снег';
    case 75:
      return 'Сильный снег';
    case 77:
      return 'Снежная крупа';
    case 80:
    case 81:
    case 82:
      return 'Ливень';
    case 85:
    case 86:
      return 'Снегопад';
    case 95:
      return 'Гроза';
    case 96:
    case 99:
      return 'Гроза с градом';
    default:
      return 'Неизвестно';
  }
}

IconData weatherIcon(int code) {
  if (code == 0 || code == 1) return Icons.wb_sunny;
  if (code == 2) return Icons.wb_cloudy;
  if (code == 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 51 && code <= 67) return Icons.water_drop;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.umbrella;
  if (code == 85 || code == 86) return Icons.ac_unit;
  if (code >= 95) return Icons.thunderstorm;
  return Icons.help_outline;
}
