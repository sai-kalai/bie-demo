# ==========================================
# Stage 1: Build the application sysimage
# ==========================================
FROM julia:1.12.2 AS builder

# Keep the existing resource constraints.
ENV JULIA_CPU_THREADS=1 \
    JULIA_NUM_PRECOMPILE_TASKS=1 \
    JULIA_HEAP_SIZE_HINT=3G \
    JULIA_PKG_PRECOMPILE_AUTO=0

WORKDIR /app

# PackageCompiler needs a C/C++ toolchain. GNU time is used for build
# diagnostics. Neither is installed in the runtime stage.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    time \
    && rm -rf /var/lib/apt/lists/*

# Install the application dependencies from the committed lockfile.
COPY Project.toml Manifest.toml ./

RUN /usr/bin/time -v julia \
    --startup-file=no \
    --project=/app \
    --heap-size-hint=6G \
    -e 'using Pkg; Pkg.instantiate(; verbose=true)'

# Keep PackageCompiler in a separate build-only environment.
COPY build/Project.toml ./build/Project.toml

RUN /usr/bin/time -v julia \
    --startup-file=no \
    --project=/app/build \
    --heap-size-hint=6G \
    -e 'using Pkg; Pkg.instantiate(; verbose=true); Pkg.precompile()'

# Copy application sources only after dependency installation to retain
# the dependency layers in the Docker cache when application code changes.
COPY . .

# Build the sysimage against the application's locked project environment.
RUN /usr/bin/time -v julia \
    --startup-file=no \
    --project=/app/build \
    --heap-size-hint=6G \
    /app/scripts/build_sysimage.jl


# ==========================================
# Stage 2: Minimal runtime
# ==========================================
FROM julia:1.12.2 AS runtime

# Keep the same Julia resource constraints at runtime.
ENV JULIA_CPU_THREADS=1 \
    JULIA_NUM_PRECOMPILE_TASKS=1 \
    JULIA_HEAP_SIZE_HINT=3G \
    JULIA_PKG_PRECOMPILE_AUTO=0

WORKDIR /app

# Copy the locked application environment and application files.
COPY --from=builder /app/Project.toml /app/Manifest.toml /app/app.jl ./
COPY --from=builder /app/src/ ./src/
COPY --from=builder /app/assets/ ./assets/

# Preserve package sources, artifacts, and compiled caches needed at runtime.
COPY --from=builder /root/.julia/ /root/.julia/

# Copy the generated sysimage.
COPY --from=builder /app/DemoWebsiteSysimage.so ./DemoWebsiteSysimage.so

EXPOSE 8080

# Keep the lightweight hello-world app.jl as the deployment entry point.
CMD ["julia", "--startup-file=no", "--project=/app", "--sysimage=/app/DemoWebsiteSysimage.so", "/app/app.jl"]
