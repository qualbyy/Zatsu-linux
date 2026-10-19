"""
Qt compatibility layer supporting both PySide6 and PyQt6 seamlessly.
Supports dynamic switching via QT_API environment variable ("PyQt6" or "PySide6").
Automatically prefers PyQt6 on Python >= 3.14 to bypass Shiboken6 PEP 384 assertion bugs.
"""

import os
import sys

preferred = os.environ.get("QT_API", "").strip().lower()

# On Python >= 3.14, Shiboken6 in PySide6 has known upstream assertion failures (pep384impl.cpp:901).
# If PyQt6 is installed, prefer it on Python 3.14+ unless QT_API is explicitly set to PySide6.
prefer_pyqt = (preferred in ("pyqt", "pyqt6")) or (not preferred and sys.version_info >= (3, 14))

IS_PYSIDE = False
IS_PYQT = False
QT_BINDING = ""
QT_VERSION = ""

def _import_pyqt6():
    global IS_PYSIDE, IS_PYQT, QT_BINDING, QT_VERSION
    global QtCore, QtGui, QtWidgets, QObject, Signal, Slot, Property
    global QUrl, QTimer, QPoint, QSize, QRect, Qt, QDateTime, QTime, QDate
    global QGuiApplication, QIcon, QPixmap, QImage, QPainter, QColor, QFont, QScreen, QKeySequence
    global QApplication, QFileDialog, QMessageBox, QQuickImageProvider, QQuickView
    global QQmlApplicationEngine, QQmlContext, QQmlComponent

    import PyQt6
    from PyQt6 import QtCore, QtGui, QtWidgets
    from PyQt6.QtCore import (
        QObject, pyqtSignal as Signal, pyqtSlot as Slot, pyqtProperty as Property,
        QUrl, QTimer, QPoint, QSize, QRect, Qt, QDateTime, QTime, QDate
    )
    from PyQt6.QtGui import (
        QGuiApplication, QIcon, QPixmap, QImage, QPainter, QColor, QFont,
        QScreen, QKeySequence
    )
    from PyQt6.QtWidgets import (
        QApplication, QFileDialog, QMessageBox
    )
    from PyQt6.QtQuick import QQuickImageProvider, QQuickView
    from PyQt6.QtQml import QQmlApplicationEngine, QQmlContext, QQmlComponent

    IS_PYSIDE = False
    IS_PYQT = True
    QT_BINDING = "PyQt6"
    QT_VERSION = PyQt6.QtCore.PYQT_VERSION_STR


def _import_pyside6():
    global IS_PYSIDE, IS_PYQT, QT_BINDING, QT_VERSION
    global QtCore, QtGui, QtWidgets, QObject, Signal, Slot, Property
    global QUrl, QTimer, QPoint, QSize, QRect, Qt, QDateTime, QTime, QDate
    global QGuiApplication, QIcon, QPixmap, QImage, QPainter, QColor, QFont, QScreen, QKeySequence
    global QApplication, QFileDialog, QMessageBox, QQuickImageProvider, QQuickView
    global QQmlApplicationEngine, QQmlContext, QQmlComponent

    import PySide6
    from PySide6 import QtCore, QtGui, QtWidgets
    from PySide6.QtCore import (
        QObject, Signal, Slot, Property, QUrl, QTimer, QPoint, QSize, QRect,
        Qt, QDateTime, QTime, QDate
    )
    from PySide6.QtGui import (
        QGuiApplication, QIcon, QPixmap, QImage, QPainter, QColor, QFont,
        QScreen, QKeySequence
    )
    from PySide6.QtWidgets import (
        QApplication, QFileDialog, QMessageBox
    )
    from PySide6.QtQuick import QQuickImageProvider, QQuickView
    from PySide6.QtQml import QQmlApplicationEngine, QQmlContext, QQmlComponent

    IS_PYSIDE = True
    IS_PYQT = False
    QT_BINDING = "PySide6"
    QT_VERSION = PySide6.__version__


if prefer_pyqt:
    try:
        _import_pyqt6()
    except ImportError:
        try:
            _import_pyside6()
        except ImportError as e:
            raise ImportError("Neither PyQt6 nor PySide6 could be loaded.") from e
else:
    try:
        _import_pyside6()
    except ImportError:
        try:
            _import_pyqt6()
        except ImportError as e:
            raise ImportError("Neither PySide6 nor PyQt6 could be loaded.") from e


def get_qt_info():
    return {
        "binding": QT_BINDING,
        "version": QT_VERSION,
        "is_pyside": IS_PYSIDE,
        "is_pyqt": IS_PYQT,
    }
