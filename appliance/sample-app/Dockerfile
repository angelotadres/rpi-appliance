# Default sample app: Candle, an open-source (GPL-3.0) GRBL G-code sender.
# It is the open analog of the north-star CNC case and exercises the toolkit's
# hard paths: opens .gcode/.nc files (web file manager), 3D toolpath rendering
# (noVNC), and serial GRBL connect (wired in Phase 2+). Built from source at
# image-build time rather than vendored, so this repo's recipe stays MIT while
# the resulting image may contain GPL software (the jlesage/distro model).
#
# Swap this app: change the build below and /startapp.sh. Phase 2 replaces this
# whole container with the boot-folder compose mechanism.
FROM jlesage/baseimage-gui:debian-12-v4.12.5

ARG CANDLE_VERSION=v11.2

# Qt5 build + runtime deps (per Candle's documented Debian/Pi OS build), plus
# Mesa for software OpenGL so the 3D visualizer renders without a GPU.
RUN add-pkg \
        cmake build-essential git ca-certificates \
        qtbase5-dev libqt5opengl5-dev libqt5serialport5-dev qtscript5-dev \
        qttools5-dev libqt5websockets5-dev qtmultimedia5-dev \
        libgl1-mesa-dri libglu1-mesa && \
    git clone --depth 1 --branch "${CANDLE_VERSION}" \
        https://github.com/Denvi/Candle.git /tmp/candle && \
    cmake -S /tmp/candle -B /tmp/candle/build \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/candle && \
    cmake --build /tmp/candle/build --config Release -j"$(nproc)" && \
    cmake --install /tmp/candle/build && \
    rm -rf /tmp/candle

# No GPU in the container — force Mesa software rendering for Qt's OpenGL view.
ENV LIBGL_ALWAYS_SOFTWARE=1

RUN set-cont-env APP_NAME "Candle"

COPY startapp.sh /startapp.sh
RUN chmod +x /startapp.sh
