
# ===========================
# Stage 1 — build pcb2gcode
# ===========================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential automake autoconf autoconf-archive libtool \
    libboost-program-options-dev libgtkmm-2.4-dev gerbv librsvg2-dev git \
    libglib2.0-bin  libgtkmm-2.4-1v5 \
    && rm -rf /var/lib/apt/lists/* 

# Clone and build

WORKDIR /src
RUN git clone https://github.com/pcb2gcode/pcb2gcode.git . 
# Fix missing version in libgerbv.pc (Ubuntu bug)
RUN sed -i 's/^Version:.*/Version: 2.10.0/' /usr/lib/x86_64-linux-gnu/pkgconfig/libgerbv.pc || \
    echo 'Version: 2.10.0' >> /usr/lib/x86_64-linux-gnu/pkgconfig/libgerbv.pc 

RUN autoreconf -fvi && ./configure && make -j"$(nproc)" && make install DESTDIR=/install 

# ===========================
# Stage 2 — runtime image
# ===========================
FROM ubuntu:22.04 

# Install runtime libraries only
RUN apt-get update && apt-get install -y \ 
    libboost-program-options1.74.0 libgtkmm-2.4-1v5 gerbv librsvg2-2 \ 
    && rm -rf /var/lib/apt/lists/* 

# Copy compiled binaries 
COPY --from=builder /install/usr/local /usr/local

# Create a working directory
WORKDIR /data

# Default command
ENTRYPOINT ["pcb2gcode"]
CMD ["--help"]
