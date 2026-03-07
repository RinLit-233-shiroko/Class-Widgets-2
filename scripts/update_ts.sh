#!/bin/bash

cd ..

pyside6-lupdate $(find src/ -name "*.py" -o -name "*.qml") -ts assets/locales/en_US.ts
pyside6-lupdate $(find src/ -name "*.py" -o -name "*.qml") -ts assets/locales/zh_CN.ts
pyside6-lupdate $(find src/ -name "*.py" -o -name "*.qml") -ts assets/locales/zh_HK.ts
pyside6-lupdate $(find src/ -name "*.py" -o -name "*.qml") -ts assets/locales/ja_JP.ts

pyside6-lrelease assets/locales/en_US.ts
pyside6-lrelease assets/locales/zh_CN.ts
pyside6-lrelease assets/locales/zh_HK.ts
pyside6-lrelease assets/locales/ja_JP.ts
