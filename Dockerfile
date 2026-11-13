FROM julia:1.12

ENV JULIA_CPU_THREADS=1
ENV JULIA_NUM_PRECOMPILE_TASKS=1
ENV JULIA_HEAP_SIZE_HINT=3G
ENV JULIA_PKG_PRECOMPILE_AUTO=0



WORKDIR /app

COPY Project.toml .
# COPY Manifest.toml .
# COPY build_sysimage.jl .
# ADD src src/.

RUN apt-get update && apt-get install -y time

# RUN /usr/bin/time -v julia create_sys_image.jl -t auto -O3 --startup-file=no --heap-size-hint=6G

RUN /usr/bin/time -v julia --project=. -e 'using Pkg; Pkg.instantiate(; verbose=true)' --heap-size-hint=6G

COPY . .

RUN /usr/bin/time -v julia --project=. -e 'using Pkg; Pkg.precompile()' --heap-size-hint=6G

EXPOSE 8080

CMD ["julia", "--project=.", "-e", "using DemoWebsite; DemoWebsite.main()"]
