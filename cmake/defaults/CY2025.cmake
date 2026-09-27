# CY2025 VFX Reference Platform versions of dependencies see https://vfxplatform.com/

IF(RV_VFX_PLATFORM STREQUAL "CY2025")
  # Year
  SET(RV_VFX_CY_YEAR
      "2025"
  )
  SET(RV_VFX_CY2025
      ON
  )
  ADD_COMPILE_DEFINITIONS(QT65ON)

  # Boost
  # NOTE: bumped from CY2025's default 1.85.0 to 1.88.0 (CY2026's pin) on request, kept alongside Qt 6.5.3/Python 3.11.
  SET(RV_DEPS_BOOST_VERSION
      "1.88.0"
  )
  SET(RV_DEPS_BOOST_MAJOR_MINOR_VERSION
      "1_88"
  )
  SET(RV_DEPS_BOOST_DOWNLOAD_HASH
      "6cd58b3cc890e4fbbc036c7629129e18"
  )

  # Imath Can find the build version in OpenRV/_build/RV_DEPS_IMATH/install/lib/
  # NOTE: bumped from CY2025's default 3.1.12 to 3.2.2 (CY2026's pin) on request. OpenEXR 3.4.3 and OCIO 2.5.0 both
  # only require Imath >= 3.1, so this bump is not strictly required by either -- done anyway to track CY2026.
  SET(RV_DEPS_IMATH_VERSION
      "3.2.2"
  )
  SET(RV_DEPS_IMATH_DOWNLOAD_HASH
      "d9c3aadc25a7d47a893b649787e59a44"
  )
  SET(RV_DEPS_IMATH_LIB_VER
      "30.${RV_DEPS_IMATH_VERSION}"
  )
  SET(RV_DEPS_IMATH_LIB_MAJOR
      "3_2"
  )

  # NumPy https://numpy.org/doc/stable/release.html
  # NOTE: kept at CY2025's default 1.26.4. Bumping to CY2026's 2.3.0 does NOT work while Qt/PySide stay at 6.5.3:
  # PySide6 6.5.3's build_scripts/utils.py:get_numpy_location() hardcodes "numpy/core/include", but NumPy 2.0 renamed
  # that directory to "numpy/_core/include". shiboken6 then fails with
  # "fatal error C1083: Cannot open include file: 'numpy/arrayobject.h'".
  SET(RV_DEPS_NUMPY_VERSION
      "1.26.4"
  )

  # OCIO https://github.com/AcademySoftwareFoundation/OpenColorIO
  # NOTE: bumped from CY2025's default 2.4.2 to 2.5.0 (the version pinned by CY2026) on request. Verified against
  # OCIO 2.5.0's share/cmake/modules/FindExtPackages.cmake: Imath MIN_VERSION is 3.1.1 -- satisfied both by the
  # Imath 3.2.2 set above and by CY2025's original 3.1.12.
  SET(RV_DEPS_OCIO_VERSION
      "2.5.0"
  )
  SET(RV_DEPS_OCIO_VERSION_SHORT
      "2_5"
  )
  SET(RV_DEPS_OCIO_DOWNLOAD_HASH
      "fd402ea99fd2c4e5b43ea31b4a3387df"
  )

  # OpenEXR https://github.com/AcademySoftwareFoundation/openexr/releases
  # NOTE: bumped from CY2025's default 3.3.6 to 3.4.3 (CY2026's pin) on request. Verified OpenEXR 3.4.3's
  # cmake/OpenEXRSetup.cmake: find_package(Imath 3.1 ...) -- satisfied by the 3.2.2 bump above (and would have been
  # satisfied by the original 3.1.12 too).
  SET(RV_DEPS_OPENEXR_VERSION
      "3.4.3"
  )
  SET(RV_DEPS_OPENEXR_DOWNLOAD_HASH
      "c11676598aa27a01a1cd21ad75b72e44"
  )
  SET(RV_DEPS_OPENEXR_LIBNAME_SUFFIX
      "3_4"
  )
  SET(RV_DEPS_OPENEXR_LIB_VERSION_SUFFIX
      "33.${RV_DEPS_OPENEXR_VERSION}"
  )
  SET(RV_DEPS_OPENEXR_PATCH_NAME
      "openexr_${RV_DEPS_OPENEXR_VERSION}_invalid_to_black"
  )

  # OpenSSL https://github.com/openssl/openssl
  SET(RV_DEPS_OPENSSL_VERSION
      "3.6.2"
  )
  SET(RV_DEPS_OPENSSL_HASH
      "f27e8f53ac612bb0e3e781a45799fb90"
  )
  SET(RV_DEPS_OPENSSL_VERSION_DOT
      ".3"
  )
  SET(RV_DEPS_OPENSSL_VERSION_UNDERSCORE
      "3"
  )

  # PySide
  SET(RV_DEPS_PYSIDE_VERSION
      "6.5.3"
  )
  SET(RV_DEPS_PYSIDE_DOWNLOAD_HASH
      "515d3249c6e743219ff0d7dd25b8c8d8"
  )
  SET(RV_DEPS_PYSIDE_TARGET
      "RV_DEPS_PYSIDE6"
  )
  SET(RV_DEPS_PYSIDE_ARCHIVE_URL
      "https://mirrors.ocf.berkeley.edu/qt/official_releases/QtForPython/pyside6/PySide6-${RV_DEPS_PYSIDE_VERSION}-src/pyside-setup-everywhere-src-${RV_DEPS_PYSIDE_VERSION}.zip"
  )

  # Python https://www.python.org/downloads/source/
  SET(RV_DEPS_PYTHON_VERSION
      "3.11.9"
  )
  SET(RV_DEPS_PYTHON_DOWNLOAD_HASH
      "392eccd4386936ffcc46ed08057db3e7"
  )
  # SET(RV_DEPS_PYTHON_VERSION "3.11.14") SET(RV_DEPS_PYTHON_DOWNLOAD_HASH "5f43ab9d5a74b9ac0dd2e20f58740f9e")

  # Qt
  SET(RV_DEPS_QT_VERSION
      "6.5.3"
  )
  SET(RV_DEPS_QT_MAJOR
      "6"
  )
ENDIF()
